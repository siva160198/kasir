module Api::V1::Admin
  class PurchaseOrdersController < ApplicationController
    def index
      authorize PurchaseOrder
      orders, pagination = paginate_api(policy_scope(PurchaseOrder), search_columns: %w[order_number status payment_status], sortable_columns: %w[created_at ordered_at total status payment_status], default_sort: :created_at, default_direction: :desc)
      render json: { purchase_orders: orders.includes(:supplier, :purchase_order_items).map { |order| order_json(order) }, suppliers: supplier_options, products: product_options, pagination: pagination }
    end
    def show
      order = PurchaseOrder.includes(:supplier, purchase_order_items: :product, goods_receipts: [ :user, { goods_receipt_items: :purchase_order_item } ]).find(params[:id]); authorize order
      render json: { purchase_order: order_json(order, detail: true), suppliers: supplier_options, products: product_options }
    end
    def create
      order = PurchaseOrder.new(order_params.except(:items).merge(user: Current.user, order_number: "PO-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}")); authorize order
      save_order!(order, order_params[:items]); render json: { purchase_order: order_json(order, detail: true) }, status: :created
    rescue ActiveRecord::RecordInvalid => error
      render_validation_error(error.record)
    end
    def update
      order = PurchaseOrder.find(params[:id]); authorize order
      unless order.status == "draft" || params.keys.all? { |key| %w[controller action id payment_status].include?(key) }
        return render_api_error("PURCHASE_NOT_EDITABLE", status: :unprocessable_content)
      end
      PurchaseOrder.transaction do
        order.assign_attributes(order_params.except(:items)); order.purchase_order_items.destroy_all if order_params[:items]
        save_order!(order, order_params[:items], new_record: false)
      end
      render json: { purchase_order: order_json(order.reload, detail: true) }
    rescue ActiveRecord::RecordInvalid => error
      render_validation_error(error.record)
    end
    def receive
      order = PurchaseOrder.includes(purchase_order_items: :product).find(params[:id]); authorize order, :receive?
      return render_api_error("PURCHASE_NOT_RECEIVABLE", status: :unprocessable_content) unless %w[ordered partially_received].include?(order.status)
      receipt = receive_order!(order)
      render json: { goods_receipt: receipt_json(receipt), purchase_order: order_json(order.reload, detail: true) }, status: :created
    rescue ActiveRecord::RecordInvalid => error
      render_validation_error(error.record)
    end
    def cancel
      order = PurchaseOrder.find(params[:id]); authorize order, :cancel?
      return render_api_error("PURCHASE_NOT_CANCELLABLE", status: :unprocessable_content) unless %w[draft ordered].include?(order.status) && order.purchase_order_items.sum(:received_quantity).zero?
      order.update!(status: "cancelled"); render json: { purchase_order: order_json(order) }
    end
    private
      def order_params = params.permit(:supplier_id, :status, :payment_status, :ordered_at, :notes, items: %i[product_id quantity unit_cost])
      def save_order!(order, items, new_record: true)
        rows = Array(items); order.errors.add(:items, :blank) if new_record && rows.empty?; raise ActiveRecord::RecordInvalid.new(order) if order.errors.any?
        PurchaseOrder.transaction do
          order.total = rows.sum { |row| row[:quantity].to_i * row[:unit_cost].to_i } if items
          order.ordered_at ||= Date.current if order.status == "ordered"; order.save!
          rows.each { |row| order.purchase_order_items.create!(product_id: row[:product_id], quantity: row[:quantity], unit_cost: row[:unit_cost], subtotal: row[:quantity].to_i * row[:unit_cost].to_i) }
        end
      end
      def receive_order!(order)
        rows = Array(params[:items]); receipt = GoodsReceipt.new(purchase_order: order, user: Current.user, receipt_number: "GR-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}", note: params[:note])
        receipt.errors.add(:items, :blank) if rows.empty?; raise ActiveRecord::RecordInvalid.new(receipt) if receipt.errors.any?
        GoodsReceipt.transaction do
          receipt.save!
          rows.each do |row|
            item = order.purchase_order_items.find { |candidate| candidate.id == row[:purchase_order_item_id].to_i }; quantity = row[:quantity].to_i
            if item.nil? || quantity <= 0 || item.received_quantity + quantity > item.quantity
              receipt.errors.add(:items, :invalid); raise ActiveRecord::RecordInvalid.new(receipt)
            end
            product = item.product.lock!; before = product.current_stock
            product.update!(current_stock: before + quantity, cost_price: item.unit_cost)
            item.update!(received_quantity: item.received_quantity + quantity)
            receipt.goods_receipt_items.create!(purchase_order_item: item, quantity: quantity)
            StockMovement.create!(product: product, user: Current.user, movement_type: "purchase", quantity: quantity, stock_before: before, stock_after: product.current_stock, note: "Penerimaan #{receipt.receipt_number}", reference_type: "GoodsReceipt", reference_id: receipt.id)
          end
          total_received = order.purchase_order_items.sum(:received_quantity); total_ordered = order.purchase_order_items.sum(:quantity)
          order.update!(status: total_received >= total_ordered ? "completed" : "partially_received")
          receipt
        end
      end
      def order_json(order, detail: false)
        json = order.as_json(only: %i[id supplier_id order_number status payment_status total ordered_at notes created_at]).merge(supplier_name: order.supplier.name, item_count: order.purchase_order_items.sum(&:quantity), received_count: order.purchase_order_items.sum(&:received_quantity))
        return json unless detail
        json.merge(items: order.purchase_order_items.map { |item| item.as_json(only: %i[id product_id quantity received_quantity unit_cost subtotal]).merge(product_name: item.product.name, sku: item.product.sku) }, receipts: order.goods_receipts.order(created_at: :desc).map { |receipt| receipt_json(receipt) })
      end
      def receipt_json(receipt) = receipt.as_json(only: %i[id receipt_number note created_at]).merge(user_email: receipt.user.email_address, items: receipt.goods_receipt_items.map { |item| item.as_json(only: %i[purchase_order_item_id quantity]) })
      def supplier_options = Supplier.active.order(:name).pluck(:id, :name).map { |id, name| { id: id, name: name } }
      def product_options = Product.active.order(:name).pluck(:id, :name, :sku, :cost_price).map { |id, name, sku, cost| { id: id, name: name, sku: sku, cost_price: cost } }
  end
end
