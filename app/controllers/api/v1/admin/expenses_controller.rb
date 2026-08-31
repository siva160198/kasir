module Api::V1::Admin
  class ExpensesController < ApplicationController
    def index
      authorize Expense
      scope = policy_scope(Expense).includes(:user)
      scope = scope.where(expense_date: params[:from]..params[:to]) if params[:from].present? && params[:to].present?
      total = scope.sum(:amount)
      records, pagination = paginate_api(scope, search_columns: %w[expense_number description category reference_number], sortable_columns: %w[expense_date amount category created_at], default_sort: :expense_date, default_direction: :desc)
      render json: { expenses: records.map { |expense| expense_json(expense) }, summary: { total: total }, pagination: pagination }
    end

    def show
      expense = Expense.find(params[:id]); authorize expense
      render json: { expense: expense_json(expense) }
    end

    def create
      expense = Expense.new(expense_params.merge(user: Current.user, expense_number: next_number)); authorize expense
      return render_validation_error(expense) unless expense.save
      audit(expense, "admin.expense_created")
      render json: { expense: expense_json(expense) }, status: :created
    end

    def update
      expense = Expense.find(params[:id]); authorize expense
      changes = expense_params.to_h.stringify_keys
      return render json: { expense: expense_json(expense) } if changes.all? { |key, value| expense.public_send(key).to_s == value.to_s }
      return render_validation_error(expense) unless expense.update(expense_params)
      audit(expense, "admin.expense_updated")
      render json: { expense: expense_json(expense) }
    end

    def destroy
      expense = Expense.find(params[:id]); authorize expense
      audit(expense, "admin.expense_deleted"); expense.destroy!; head :no_content
    end

    private
      def expense_params = params.permit(:expense_date, :category, :description, :amount, :payment_method, :reference_number, :note)
      def next_number = "EXP-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
      def expense_json(expense) = expense.as_json(only: %i[id expense_number expense_date category description amount payment_method reference_number note created_at updated_at]).merge(user_email: expense.user.email_address)
      def audit(expense, action) = AuditLog.record!(action: action, actor: Current.user, auditable: expense, metadata: expense.slice("expense_number", "amount", "category"), request: request)
  end
end
