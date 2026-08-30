require "test_helper"

class Api::V1::Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "anonymous users receive unauthorized" do
    get api_v1_admin_dashboard_url, as: :json
    assert_response :unauthorized
    assert_api_error "AUTHENTICATION_REQUIRED"
  end

  test "members receive forbidden" do
    sign_in_as users(:two)
    get api_v1_admin_dashboard_url, as: :json
    assert_response :forbidden
    assert_api_error "FORBIDDEN"
  end

  test "admins can view the dashboard" do
    admin = users(:one)
    shift = CashierShift.create!(user: admin, shift_number: "SFT-DASHBOARD-TEST", status: "open", opened_at: Time.current, opening_cash: 100_000)
    sale = Sale.create!(cashier_shift: shift, user: admin, sale_number: "SALE-DASHBOARD-TEST", client_token: "dashboard-test", status: "completed", subtotal: 25_000, discount: 0, tax_amount: 0, rounding_amount: 0, total: 25_000, completed_at: Time.current)
    Payment.create!(sale: sale, payment_method: "cash", amount: 25_000, received_amount: 30_000, change_amount: 5_000)
    sign_in_as admin
    get api_v1_admin_dashboard_url, as: :json

    assert_response :success
    assert_equal "admin", response.parsed_body.dig("user", "role")
    assert response.parsed_body.dig("summary", "net_sales").is_a?(Integer)
    assert_equal "today", response.parsed_body.fetch("period")
    assert_equal 13, response.parsed_body.fetch("weekly_sales").size
    assert_equal Payment::METHODS, response.parsed_body.fetch("payments").pluck("method")
    assert response.parsed_body.dig("stock", "low_count").is_a?(Integer)
    assert response.parsed_body.key?("recent_sales")
    assert_equal admin.email_address, response.parsed_body.dig("shifts", "items", 0, "cashier")
    assert_equal 25_000, response.parsed_body.dig("summary", "net_sales")
  end

  test "admins can filter dashboard by week and month" do
    sign_in_as users(:one)

    get api_v1_admin_dashboard_url(period: "week"), as: :json
    assert_response :success
    assert_equal "week", response.parsed_body.fetch("period")
    assert_equal 7, response.parsed_body.fetch("weekly_sales").size

    get api_v1_admin_dashboard_url(period: "month"), as: :json
    assert_response :success
    assert_equal "month", response.parsed_body.fetch("period")
    assert_equal Date.current.day, response.parsed_body.fetch("weekly_sales").size
  end
end
