require "test_helper"

class Api::V1::Admin::ExpensesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "admin creates updates lists and deletes an expense" do
    assert_difference([ "Expense.count", "AuditLog.count" ], 1) do
      post api_v1_admin_expenses_url, params: { expense_date: Date.current, category: "utilities", description: "Tagihan listrik", amount: 250_000, payment_method: "transfer" }, as: :json
    end
    assert_response :created
    expense = Expense.find(response.parsed_body.dig("expense", "id"))

    get api_v1_admin_expenses_url
    assert_response :success
    assert_equal 250_000, response.parsed_body.dig("summary", "total")

    patch api_v1_admin_expense_url(expense), params: { amount: 275_000 }, as: :json
    assert_response :success
    assert_equal 275_000, expense.reload.amount

    assert_difference("Expense.count", -1) do
      assert_difference("AuditLog.count", 1) do
        delete api_v1_admin_expense_url(expense), as: :json
      end
    end
    assert_response :no_content
  end

  test "invalid expense follows validation contract" do
    post api_v1_admin_expenses_url, params: { expense_date: Date.current, category: "unknown", description: "", amount: 0 }, as: :json
    assert_response :unprocessable_content
    assert_api_error "VALIDATION_FAILED"
  end

  test "member cannot view expenses" do
    sign_in_as(users(:two)); get api_v1_admin_expenses_url
    assert_response :forbidden
  end
end
