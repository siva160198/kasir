module Api::V1::Admin
  class SuppliersController < ApplicationController
    def index
      authorize Supplier
      suppliers, pagination = paginate_api(policy_scope(Supplier), search_columns: %w[name contact_name phone email], sortable_columns: %w[name active created_at], default_sort: :name)
      render json: { suppliers: suppliers.map { |supplier| supplier_json(supplier) }, pagination: pagination }
    end
    def show
      supplier = Supplier.find(params[:id]); authorize supplier
      render json: { supplier: supplier_json(supplier) }
    end
    def create
      supplier = Supplier.new(supplier_params); authorize supplier
      return render_validation_error(supplier) unless supplier.save
      render json: { supplier: supplier_json(supplier) }, status: :created
    end
    def update
      supplier = Supplier.find(params[:id]); authorize supplier
      return render_validation_error(supplier) unless supplier.update(supplier_params)
      render json: { supplier: supplier_json(supplier) }
    end
    def destroy
      supplier = Supplier.find(params[:id]); authorize supplier
      supplier.destroy!; head :no_content
    rescue ActiveRecord::DeleteRestrictionError
      render_api_error("SUPPLIER_IN_USE", status: :unprocessable_content)
    end
    private
      def supplier_params = params.permit(:name, :contact_name, :phone, :email, :address, :active)
      def supplier_json(supplier) = supplier.as_json(only: %i[id name contact_name phone email address active created_at updated_at]).merge(purchase_orders_count: supplier.purchase_orders.count)
  end
end
