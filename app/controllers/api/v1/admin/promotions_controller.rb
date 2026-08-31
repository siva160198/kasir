module Api::V1::Admin
  class PromotionsController < ApplicationController
    def index
      authorize Promotion
      records, pagination = paginate_api(policy_scope(Promotion), search_columns: %w[name code discount_type], sortable_columns: %w[name starts_at ends_at usage_count active], default_sort: :created_at, default_direction: :desc)
      render json: { promotions: records.map { |promotion| promotion_json(promotion) }, pagination: pagination }
    end

    def show
      promotion = Promotion.find(params[:id]); authorize promotion
      render json: { promotion: promotion_json(promotion) }
    end

    def create
      promotion = Promotion.new(promotion_params); authorize promotion
      return render_validation_error(promotion) unless promotion.save
      audit(promotion, "admin.promotion_created")
      render json: { promotion: promotion_json(promotion) }, status: :created
    end

    def update
      promotion = Promotion.find(params[:id]); authorize promotion
      return render_validation_error(promotion) unless promotion.update(promotion_params)
      audit(promotion, "admin.promotion_updated")
      render json: { promotion: promotion_json(promotion) }
    end

    def destroy
      promotion = Promotion.find(params[:id]); authorize promotion
      promotion.destroy!; audit(promotion, "admin.promotion_deleted"); head :no_content
    rescue ActiveRecord::DeleteRestrictionError
      render_api_error("PROMOTION_IN_USE", status: :unprocessable_content)
    end

    private
      def promotion_params = params.permit(:name, :code, :discount_type, :value, :minimum_purchase, :maximum_discount, :starts_at, :ends_at, :usage_limit, :active)
      def promotion_json(promotion) = promotion.as_json(only: %i[id name code discount_type value minimum_purchase maximum_discount starts_at ends_at usage_limit usage_count active created_at updated_at]).merge(currently_available: promotion.available_for?(promotion.minimum_purchase))
      def audit(promotion, action) = AuditLog.record!(action: action, actor: Current.user, auditable: promotion, metadata: promotion.slice("code", "discount_type", "value"), request: request)
  end
end
