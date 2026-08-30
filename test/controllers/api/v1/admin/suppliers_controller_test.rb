require "test_helper"

class Api::V1::Admin::SuppliersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }
  test "creates and updates a supplier" do
    post api_v1_admin_suppliers_url, params: { name: "PT Segar", phone: "081234", active: true }, as: :json
    assert_response :created
    id = response.parsed_body.dig("supplier", "id")
    patch api_v1_admin_supplier_url(id), params: { contact_name: "Made" }, as: :json
    assert_response :success
    assert_equal "Made", Supplier.find(id).contact_name
  end
end
