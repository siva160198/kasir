module Api::V1::Admin
  class InventoryController < ApplicationController
    def index
      authorize :inventory, :index?, policy_class: InventoryPolicy
      products, pagination = paginate_api(policy_scope(Product), search_columns: %w[name sku barcode], sortable_columns: %w[name current_stock minimum_stock], default_sort: :name)
      render json: { inventory: products.includes(:category, :preferred_supplier).map { |p| product_json(p) }, recommendations: recommendations, suppliers: Supplier.active.order(:name).pluck(:id, :name).map { |id, name| { id: id, name: name } }, pagination: pagination }
    end
    def alerts
      authorize :inventory, :index?, policy_class: InventoryPolicy
      rows = recommendations
      render json: { count: rows.size, alerts: rows.first(5) }
    end
    def preferred_supplier
      authorize :inventory, :index?, policy_class: InventoryPolicy
      product = Product.find(params[:id]); product.update!(preferred_supplier_id: params[:supplier_id].presence)
      render json: { product: product_json(product) }
    rescue ActiveRecord::RecordInvalid => error
      render_validation_error(error.record)
    end
    def create_drafts
      authorize PurchaseOrder.new, :create?
      products = Product.where(id: Array(params[:product_ids])).includes(:preferred_supplier)
      missing = products.select { |product| product.preferred_supplier.nil? }
      return render_api_error("SUPPLIER_REQUIRED", status: :unprocessable_content, details: { product_ids: missing.map(&:id) }) if missing.any?
      created = []
      PurchaseOrder.transaction do
        products.group_by(&:preferred_supplier).each do |supplier, group|
          order = PurchaseOrder.create!(supplier: supplier, user: Current.user, order_number: "PO-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}", status: "draft", payment_status: "unpaid", total: 0, notes: "Draft dari rekomendasi restock")
          total = group.sum do |product|
            quantity = recommendation_for(product)[:recommended_quantity]
            order.purchase_order_items.create!(product: product, quantity: quantity, unit_cost: product.cost_price, subtotal: quantity * product.cost_price)
            quantity * product.cost_price
          end
          order.update!(total: total); created << order
        end
      end
      render json: { purchase_orders: created.map { |order| { id: order.id, order_number: order.order_number, supplier_name: order.supplier.name } } }, status: :created
    end
    private
      def forecast_days = [ 7, 30 ].include?(params[:days].to_i) ? params[:days].to_i : 7
      def sold_quantities = @sold_quantities ||= SaleItem.joins(:sale).where(sales: { completed_at: 30.days.ago.beginning_of_day..Time.current }).group(:product_id).sum(:quantity)
      def recommendation_for(product)
        average = sold_quantities.fetch(product.id, 0) / 30.0
        target = [ product.minimum_stock, (average * forecast_days).ceil ].max
        { id: product.id, name: product.name, sku: product.sku, current_stock: product.current_stock, minimum_stock: product.minimum_stock, average_daily_sales: average.round(2), recommended_quantity: [ target - product.current_stock, 0 ].max, preferred_supplier_id: product.preferred_supplier_id, preferred_supplier_name: product.preferred_supplier&.name, stock_status: product.current_stock.zero? ? "out" : "low" }
      end
      def recommendations = Product.active.includes(:preferred_supplier).where("current_stock <= minimum_stock").map { |product| recommendation_for(product) }.select { |row| row[:recommended_quantity].positive? }.sort_by { |row| [ row[:stock_status] == "out" ? 0 : 1, -row[:recommended_quantity] ] }
      def product_json(p) = p.as_json(only: %i[id name sku barcode current_stock minimum_stock unit active preferred_supplier_id]).merge(category_name: p.category.name, preferred_supplier_name: p.preferred_supplier&.name, stock_status: p.current_stock.zero? ? "out" : p.current_stock <= p.minimum_stock ? "low" : "available")
  end
end
