module Api::V1::Admin
  class SalesController < ApplicationController
    def catalog
      authorize Sale, :catalog?
      products = Product.active.includes(:category).where("current_stock > 0").order(:name).limit(100)
      setting = StoreSetting.current
      customers = Current.user.can?("customers.view") ? Customer.active.order(:name).limit(100) : Customer.none
      promotions = Promotion.currently_active.order(:code).select { |promotion| promotion.usage_limit.nil? || promotion.usage_count < promotion.usage_limit }
      render json: { products: products.map { |p| p.as_json(only: %i[id name sku barcode selling_price current_stock unit]).merge(category_name: p.category.name) }, customers: customers.as_json(only: %i[id customer_number name phone member points]), promotions: promotions.as_json(only: %i[id name code discount_type value minimum_purchase maximum_discount ends_at]), store_setting: setting.as_json(only: %i[store_name address phone email tax_id currency tax_rate prices_include_tax rounding_unit receipt_width receipt_header receipt_footer show_cashier show_sku show_tax printer_name printer_copies]) }
    end
    def index
      authorize Sale
      sales, pagination = paginate_api(policy_scope(Sale), search_columns: %w[sale_number status], sortable_columns: %w[completed_at total sale_number], default_sort: :completed_at, default_direction: :desc)
      render json: { sales: sales.includes(:user, :cashier_shift, :customer, :promotion, :payments, :sale_items).map { |s| sale_json(s) }, pagination: pagination }
    end
    def show
      sale = Sale.includes(:user, :cashier_shift, :customer, :promotion, :sale_items, :payments, sale_refunds: [ :requested_by, :reviewed_by, { sale_refund_items: :sale_item } ]).find(params[:id])
      authorize sale
      render json: { sale: sale_json(sale, detail: true) }
    end
    def create
      authorize Sale.new(user: Current.user, cashier_shift: Current.user.cashier_shifts.open.first)
      existing = Current.user.sales.find_by(client_token: params[:client_token]); return render json: { sale: sale_json(existing) } if existing
      shift = Current.user.cashier_shifts.open.first
      unless shift then return render_api_error("SHIFT_REQUIRED", status: :unprocessable_content) end
      unless shift.pos_verified_for?(Current.session)
        return render_api_error("POS_VERIFICATION_REQUIRED", status: :unauthorized)
      end
      sale = checkout!(shift)
      render json: { sale: sale_json(sale) }, status: :created
    rescue ActiveRecord::RecordInvalid => error
      render_validation_error(error.record)
    end
    private
      def checkout!(shift)
        rows = Array(params[:items]); raise ActiveRecord::RecordInvalid.new(Sale.new.tap { |s| s.errors.add(:items, :blank) }) if rows.empty?
        Sale.transaction do
          products = Product.lock.where(id: rows.pluck(:product_id)).index_by(&:id)
          customer = params[:customer_id].present? ? Customer.active.find(params[:customer_id]) : nil
          sale = Sale.create!(cashier_shift: shift, user: Current.user, customer: customer, sale_number: "TRX-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}", client_token: params[:client_token], subtotal: 0, total: 0, completed_at: Time.current)
          item_discount = 0
          subtotal = rows.sum do |row|
            product = products[row[:product_id].to_i]; quantity = row[:quantity].to_i
            unless product && quantity.positive? && product.current_stock >= quantity
              sale.errors.add(:items, :invalid); raise ActiveRecord::RecordInvalid.new(sale)
            end
            gross = product.selling_price * quantity
            discount = row[:discount].to_i
            unless discount.between?(0, gross)
              sale.errors.add(:items, :invalid); raise ActiveRecord::RecordInvalid.new(sale)
            end
            amount = gross - discount
            item_discount += discount
            sale.sale_items.create!(product: product, product_name: product.name, sku: product.sku, quantity: quantity, unit_price: product.selling_price, cost_price: product.cost_price, discount: discount, subtotal: amount)
            before = product.current_stock; product.update!(current_stock: before - quantity)
            StockMovement.create!(product: product, user: Current.user, movement_type: "sale", quantity: -quantity, stock_before: before, stock_after: product.current_stock, note: "Penjualan #{sale.sale_number}", reference_type: "Sale", reference_id: sale.id)
            gross
          end
          setting = StoreSetting.current
          promotion = params[:promotion_code].present? ? Promotion.lock.find_by("UPPER(code) = ?", params[:promotion_code].to_s.strip.upcase) : nil
          if params[:promotion_code].present? && (!promotion || !promotion.available_for?(subtotal))
            sale.errors.add(:promotion_code, :invalid); raise ActiveRecord::RecordInvalid.new(sale)
          end
          promotion_discount = promotion ? promotion.discount_for(subtotal - item_discount) : 0
          discount = item_discount + promotion_discount
          discounted_subtotal = subtotal - discount
          rate = setting.tax_rate.to_d / 100
          tax = setting.prices_include_tax ? (discounted_subtotal - (discounted_subtotal / (1 + rate))).round : (discounted_subtotal * rate).round
          before_rounding = setting.prices_include_tax ? discounted_subtotal : discounted_subtotal + tax
          total = setting.rounding_unit == 1 ? before_rounding : (before_rounding.to_f / setting.rounding_unit).round * setting.rounding_unit
          sale.update_columns(subtotal: subtotal, discount: discount, promotion_id: promotion&.id, tax_amount: tax, rounding_amount: total - before_rounding, total: total)
          create_payments!(sale, shift, total)
          promotion&.increment!(:usage_count)
          customer&.increment!(:points, total / 10_000) if customer&.member?
          sale
        end
      end
      def sale_json(s, detail: false)
        payment = s.payments.first
        payment_label = s.payments.size > 1 ? "split" : payment&.payment_method
        json = s.as_json(only: %i[id sale_number status subtotal discount tax_amount rounding_amount total completed_at notes]).merge(user_email: s.user.email_address, cashier_shift_number: s.cashier_shift.shift_number, item_count: s.sale_items.sum(&:quantity), payment_method: payment_label, received_amount: s.payments.sum(&:received_amount), change_amount: s.payments.sum(&:change_amount), reference_number: payment&.reference_number, customer_name: s.customer&.name, promotion_code: s.promotion&.code)
        return json unless detail

        approved_quantities = SaleRefundItem.joins(:sale_refund).where(sale_refunds: { sale_id: s.id, status: "approved" }).group(:sale_item_id).sum(:quantity)
        reserved_quantities = SaleRefundItem.joins(:sale_refund).where(sale_refunds: { sale_id: s.id, status: %w[pending approved] }).group(:sale_item_id).sum(:quantity)
        json.merge(
          items: s.sale_items.map { |item| item.as_json(only: %i[id product_id product_name sku quantity unit_price cost_price discount subtotal]).merge(refunded_quantity: approved_quantities.fetch(item.id, 0), refundable_quantity: item.quantity - reserved_quantities.fetch(item.id, 0)) },
          payments: s.payments.map { |row| row.as_json(only: %i[id payment_method amount received_amount change_amount reference_number]) },
          refunds: s.sale_refunds.order(created_at: :desc).map { |refund| refund.as_json(only: %i[id refund_number refund_type status total reason review_note created_at reviewed_at]).merge(requested_by: refund.requested_by.email_address, reviewed_by: refund.reviewed_by&.email_address, items: refund.sale_refund_items.map { |ri| ri.as_json(only: %i[id sale_item_id quantity unit_price subtotal]).merge(product_name: ri.sale_item.product_name) }) }
        )
      end

      def create_payments!(sale, shift, total)
        rows = Array(params[:payments])
        rows = [ { payment_method: params[:payment_method].presence || "cash", amount: total, received_amount: params[:received_amount], reference_number: params[:reference_number] } ] if rows.empty?
        normalized = rows.map do |row|
          method = row[:payment_method].to_s
          amount = row[:amount].to_i
          received = method == "cash" ? row[:received_amount].to_i : amount
          unless Payment::METHODS.include?(method) && amount.positive? && received >= amount
            sale.errors.add(:payments, :invalid); raise ActiveRecord::RecordInvalid.new(sale)
          end
          { payment_method: method, amount: amount, received_amount: received, change_amount: method == "cash" ? received - amount : 0, reference_number: row[:reference_number].to_s.strip.presence }
        end
        unless normalized.sum { |row| row[:amount] } == total
          sale.errors.add(:payments, :invalid); raise ActiveRecord::RecordInvalid.new(sale)
        end
        normalized.each { |row| sale.payments.create!(row) }
        cash_total = normalized.select { |row| row[:payment_method] == "cash" }.sum { |row| row[:amount] }
        CashMovement.create!(cashier_shift: shift, user: Current.user, movement_type: "sale", amount: cash_total, note: "Penjualan #{sale.sale_number}", reference_type: "Sale", reference_id: sale.id) if cash_total.positive?
      end
  end
end
