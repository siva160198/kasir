module Api::V1::Admin
  class SalesController < ApplicationController
    def catalog
      authorize Sale, :catalog?
      products = Product.active.includes(:category).where("current_stock > 0").order(:name).limit(100)
      setting = StoreSetting.current
      render json: { products: products.map { |p| p.as_json(only: %i[id name sku barcode selling_price current_stock unit]).merge(category_name: p.category.name) }, store_setting: setting.as_json(only: %i[store_name address phone email tax_id currency tax_rate prices_include_tax rounding_unit receipt_width receipt_header receipt_footer show_cashier show_sku show_tax printer_name printer_copies]) }
    end
    def index
      authorize Sale
      sales, pagination = paginate_api(policy_scope(Sale), search_columns: %w[sale_number status], sortable_columns: %w[completed_at total sale_number], default_sort: :completed_at, default_direction: :desc)
      render json: { sales: sales.includes(:user, :cashier_shift, :payments, :sale_items).map { |s| sale_json(s) }, pagination: pagination }
    end
    def show
      sale = Sale.includes(:user, :cashier_shift, :sale_items, :payments, sale_refunds: [ :requested_by, :reviewed_by, { sale_refund_items: :sale_item } ]).find(params[:id])
      authorize sale
      render json: { sale: sale_json(sale, detail: true) }
    end
    def create
      authorize Sale.new(user: Current.user, cashier_shift: Current.user.cashier_shifts.open.first)
      existing = Current.user.sales.find_by(client_token: params[:client_token]); return render json: { sale: sale_json(existing) } if existing
      shift = Current.user.cashier_shifts.open.first
      unless shift then return render_api_error("SHIFT_REQUIRED", status: :unprocessable_content) end
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
          sale = Sale.create!(cashier_shift: shift, user: Current.user, sale_number: "TRX-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}", client_token: params[:client_token], subtotal: 0, total: 0, completed_at: Time.current)
          subtotal = rows.sum do |row|
            product = products[row[:product_id].to_i]; quantity = row[:quantity].to_i
            unless product && quantity.positive? && product.current_stock >= quantity
              sale.errors.add(:items, :invalid); raise ActiveRecord::RecordInvalid.new(sale)
            end
            amount = product.selling_price * quantity
            sale.sale_items.create!(product: product, product_name: product.name, sku: product.sku, quantity: quantity, unit_price: product.selling_price, cost_price: product.cost_price, subtotal: amount)
            before = product.current_stock; product.update!(current_stock: before - quantity)
            StockMovement.create!(product: product, user: Current.user, movement_type: "sale", quantity: -quantity, stock_before: before, stock_after: product.current_stock, note: "Penjualan #{sale.sale_number}", reference_type: "Sale", reference_id: sale.id)
            amount
          end
          method = params[:payment_method].presence || "cash"
          unless Payment::METHODS.include?(method) then sale.errors.add(:payment_method, :inclusion); raise ActiveRecord::RecordInvalid.new(sale) end
          setting = StoreSetting.current
          rate = setting.tax_rate.to_d / 100
          tax = setting.prices_include_tax ? (subtotal - (subtotal / (1 + rate))).round : (subtotal * rate).round
          before_rounding = setting.prices_include_tax ? subtotal : subtotal + tax
          total = setting.rounding_unit == 1 ? before_rounding : (before_rounding.to_f / setting.rounding_unit).round * setting.rounding_unit
          received = method == "cash" ? params[:received_amount].to_i : total
          sale.update_columns(subtotal: subtotal, tax_amount: tax, rounding_amount: total - before_rounding, total: total)
          if received < total then sale.errors.add(:received_amount, :greater_than_or_equal_to, count: total); raise ActiveRecord::RecordInvalid.new(sale) end
          sale.payments.create!(payment_method: method, amount: total, received_amount: received, change_amount: method == "cash" ? received - total : 0, reference_number: params[:reference_number].to_s.strip.presence)
          if method == "cash"
            CashMovement.create!(cashier_shift: shift, user: Current.user, movement_type: "sale", amount: total, note: "Penjualan #{sale.sale_number}", reference_type: "Sale", reference_id: sale.id)
          end
          sale
        end
      end
      def sale_json(s, detail: false)
        payment = s.payments.first
        json = s.as_json(only: %i[id sale_number status subtotal discount tax_amount rounding_amount total completed_at notes]).merge(user_email: s.user.email_address, cashier_shift_number: s.cashier_shift.shift_number, item_count: s.sale_items.sum(&:quantity), payment_method: payment&.payment_method, received_amount: payment&.received_amount, change_amount: payment&.change_amount, reference_number: payment&.reference_number)
        return json unless detail

        approved_quantities = SaleRefundItem.joins(:sale_refund).where(sale_refunds: { sale_id: s.id, status: "approved" }).group(:sale_item_id).sum(:quantity)
        reserved_quantities = SaleRefundItem.joins(:sale_refund).where(sale_refunds: { sale_id: s.id, status: %w[pending approved] }).group(:sale_item_id).sum(:quantity)
        json.merge(
          items: s.sale_items.map { |item| item.as_json(only: %i[id product_id product_name sku quantity unit_price cost_price subtotal]).merge(refunded_quantity: approved_quantities.fetch(item.id, 0), refundable_quantity: item.quantity - reserved_quantities.fetch(item.id, 0)) },
          refunds: s.sale_refunds.order(created_at: :desc).map { |refund| refund.as_json(only: %i[id refund_number refund_type status total reason review_note created_at reviewed_at]).merge(requested_by: refund.requested_by.email_address, reviewed_by: refund.reviewed_by&.email_address, items: refund.sale_refund_items.map { |ri| ri.as_json(only: %i[id sale_item_id quantity unit_price subtotal]).merge(product_name: ri.sale_item.product_name) }) }
        )
      end
  end
end
