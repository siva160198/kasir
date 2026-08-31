module Api::V1::Admin
  class StockCountsController < ApplicationController
    def index
      authorize StockCount
      records, pagination = paginate_api(policy_scope(StockCount).includes(:created_by, :stock_count_items), search_columns: %w[count_number status notes], sortable_columns: %w[counted_on status created_at finalized_at], default_sort: :created_at, default_direction: :desc)
      render json: { stock_counts: records.map { |count| count_json(count) }, pagination: pagination }
    end

    def show
      count = StockCount.includes(stock_count_items: :product).find(params[:id]); authorize count
      render json: { stock_count: count_json(count, detail: true) }
    end

    def create
      count = StockCount.new(count_params.merge(created_by: Current.user, count_number: next_number)); authorize count
      StockCount.transaction do
        count.save!
        Product.active.order(:name).find_each do |product|
          count.stock_count_items.create!(product: product, system_stock: product.current_stock, unit_cost: product.cost_price)
        end
      end
      AuditLog.record!(action: "admin.stock_count_created", actor: Current.user, auditable: count, metadata: { count_number: count.count_number, items: count.stock_count_items.size }, request: request)
      render json: { stock_count: count_json(count, detail: true) }, status: :created
    rescue ActiveRecord::RecordInvalid => error
      render_validation_error(error.record)
    end

    def update_item
      count = StockCount.find(params[:id]); authorize count, :update?
      item = count.stock_count_items.find(params[:item_id])
      return render_validation_error(item) unless item.update(counted_stock: params[:counted_stock], difference: params[:counted_stock].to_i - item.system_stock)
      render json: { item: item_json(item) }
    end

    def finalize
      count = StockCount.includes(stock_count_items: :product).find(params[:id]); authorize count, :finalize?
      missing = count.stock_count_items.select { |item| item.counted_stock.nil? }
      if missing.any?
        count.errors.add(:stock_count_items, :blank)
        return render_validation_error(count)
      end
      StockCount.transaction do
        count.stock_count_items.each do |item|
          product = Product.lock.find(item.product_id)
          difference = item.counted_stock - product.current_stock
          item.update!(system_stock: product.current_stock, difference: difference)
          next if difference.zero?
          StockMovement.create!(product: product, user: Current.user, movement_type: "stock_opname", quantity: difference, stock_before: product.current_stock, stock_after: item.counted_stock, note: "Stock opname #{count.count_number}", reference_type: "StockCount", reference_id: count.id)
          product.update!(current_stock: item.counted_stock)
        end
        count.update!(status: "completed", finalized_by: Current.user, finalized_at: Time.current)
      end
      AuditLog.record!(action: "admin.stock_count_finalized", actor: Current.user, auditable: count, metadata: { count_number: count.count_number, difference: count.stock_count_items.sum(&:difference) }, request: request)
      render json: { stock_count: count_json(count, detail: true) }
    end

    private
      def count_params = params.permit(:counted_on, :notes)
      def next_number = "SO-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
      def item_json(item) = item.as_json(only: %i[id product_id system_stock counted_stock difference unit_cost]).merge(product_name: item.product.name, sku: item.product.sku, unit: item.product.unit, difference_value: item.difference.to_i * item.unit_cost)
      def count_json(count, detail: false)
        items = count.stock_count_items
        json = count.as_json(only: %i[id count_number counted_on status notes finalized_at created_at]).merge(created_by_email: count.created_by.email_address, item_count: items.size, counted_count: items.count { |item| !item.counted_stock.nil? }, total_difference: items.sum { |item| item.difference.to_i }, difference_value: items.sum { |item| item.difference.to_i * item.unit_cost })
        detail ? json.merge(items: items.map { |item| item_json(item) }) : json
      end
  end
end
