require "test_helper"

class Api::V1::Admin::CustomersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "admin manages a customer" do
    post api_v1_admin_customers_url, params: { name: "Komang Sari", phone: "08123456789", member: true, active: true }, as: :json
    assert_response :created
    customer = Customer.find(response.parsed_body.dig("customer", "id"))
    assert_match(/^CUS-/, customer.customer_number)

    get api_v1_admin_customer_url(customer)
    assert_response :success
    assert_equal [], response.parsed_body.dig("customer", "recent_sales")

    patch api_v1_admin_customer_url(customer), params: { name: "Komang Sari Dewi" }, as: :json
    assert_response :success
    assert_equal "Komang Sari Dewi", customer.reload.name

    assert_difference("Customer.count", -1) { delete api_v1_admin_customer_url(customer), as: :json }
    assert_response :no_content
  end

  test "member cannot list customers" do
    sign_in_as(users(:two)); get api_v1_admin_customers_url
    assert_response :forbidden
  end
end
