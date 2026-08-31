module Api::V1::Admin
  class CustomersController < ApplicationController
    def index
      authorize Customer
      records, pagination = paginate_api(policy_scope(Customer), search_columns: %w[customer_number name phone email], sortable_columns: %w[name points member created_at], default_sort: :name)
      render json: { customers: records.map { |customer| customer_json(customer) }, pagination: pagination }
    end

    def show
      customer = Customer.find(params[:id]); authorize customer
      sales = customer.sales.order(completed_at: :desc).limit(10)
      render json: { customer: customer_json(customer).merge(recent_sales: sales.map { |sale| sale.as_json(only: %i[id sale_number total completed_at]) }) }
    end

    def create
      customer = Customer.new(customer_params.merge(customer_number: next_number)); authorize customer
      return render_validation_error(customer) unless customer.save
      audit(customer, "admin.customer_created")
      render json: { customer: customer_json(customer) }, status: :created
    end

    def update
      customer = Customer.find(params[:id]); authorize customer
      return render_validation_error(customer) unless customer.update(customer_params)
      audit(customer, "admin.customer_updated")
      render json: { customer: customer_json(customer) }
    end

    def destroy
      customer = Customer.find(params[:id]); authorize customer
      customer.destroy!; audit(customer, "admin.customer_deleted"); head :no_content
    rescue ActiveRecord::DeleteRestrictionError
      render_api_error("CUSTOMER_IN_USE", status: :unprocessable_content)
    end

    private
      def customer_params = params.permit(:name, :phone, :email, :address, :member, :active)
      def next_number = "CUS-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
      def customer_json(customer) = customer.as_json(only: %i[id customer_number name phone email address member points active created_at updated_at]).merge(sales_count: customer.sales.count, total_spent: customer.sales.sum(:total))
      def audit(customer, action) = AuditLog.record!(action: action, actor: Current.user, auditable: customer, metadata: customer.slice("customer_number", "name", "member"), request: request)
  end
end
