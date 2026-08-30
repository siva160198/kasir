module Api::V1::Admin
  class StockMovementsController < ApplicationController
    OUT_TYPES = %w[adjustment_out damaged lost internal_use].freeze
    def index
      authorize StockMovement
      records, pagination = paginate_api(policy_scope(StockMovement), search_columns: %w[movement_type note], sortable_columns: %w[created_at movement_type quantity stock_after], default_sort: :created_at, default_direction: :desc)
      render json: { stock_movements: records.includes(:product, :user).map { |m| movement_json(m) }, pagination: pagination }
    end
    def show
      product = Product.find(params[:id]); authorize StockMovement.new(product: product)
      render json: { product: product.as_json(only: %i[id name sku current_stock minimum_stock unit]) }
    end
    def create
      movement = nil
      Product.transaction do
        product = Product.lock.find(params[:product_id]); movement = StockMovement.new(movement_params.merge(product: product, user: Current.user))
        authorize movement
        amount = params[:quantity].to_i.abs; delta = OUT_TYPES.include?(movement.movement_type) ? -amount : amount
        movement.quantity = delta; movement.stock_before = product.current_stock; movement.stock_after = product.current_stock + delta
        return render_validation_error(movement) unless movement.valid?
        if movement.stock_after.negative? then movement.errors.add(:quantity, :less_than_or_equal_to, count: product.current_stock); return render_validation_error(movement) end
        movement.save!; product.update!(current_stock: movement.stock_after)
      end
      AuditLog.record!(action: "admin.stock_adjusted", actor: Current.user, auditable: movement.product, metadata: movement.slice("movement_type", "quantity", "stock_before", "stock_after", "note"), request: request)
      render json: { stock_movement: movement_json(movement) }, status: :created
    end
    private
      def movement_params = params.permit(:movement_type, :note)
      def movement_json(m) = m.as_json(only: %i[id product_id movement_type quantity stock_before stock_after note created_at]).merge(product_name: m.product.name, user_email: m.user.email_address)
  end
end
