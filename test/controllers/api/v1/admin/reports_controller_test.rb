require "test_helper"

class Api::V1::Admin::ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    product = products(:coffee)
    product.update!(current_stock: 10)
    CashierShift.create!(user: users(:one), shift_number: "SFT-REPORT", opened_at: Time.current, opening_cash: 50_000, pos_verified_at: Time.current, pos_verified_session_id: users(:one).sessions.order(:id).last.id)
    post api_v1_admin_sales_url, params: { client_token: SecureRandom.uuid, received_amount: 50_000, items: [ { product_id: product.id, quantity: 2 } ] }, as: :json
  end

  test "returns report summary and product ranking" do
    get api_v1_admin_report_url, params: { from: Date.current.iso8601, to: Date.current.iso8601 }
    assert_response :success
    assert_equal 30_000, response.parsed_body.dig("summary", "gross_sales")
    assert_equal 1, response.parsed_body.dig("summary", "transactions")
    assert_equal "Kopi Susu", response.parsed_body.dig("products", 0, "name")
    assert_equal 30_000, response.parsed_body.dig("payments", "cash")
  end

  test "exports report as csv" do
    get export_api_v1_admin_report_url, params: { from: Date.current.iso8601, to: Date.current.iso8601 }
    assert_response :success
    assert_includes response.media_type, "text/csv"
    assert_includes response.body, "Kopi Susu"
  end
end
