require "test_helper"

class Api::V1::Admin::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "admin manages products and receives category options" do
    get api_v1_admin_products_url, params: { search: "KOPI" }
    assert_response :success
    assert_equal [ products(:coffee).id ], response.parsed_body.fetch("products").pluck("id")
    assert_includes response.parsed_body.fetch("categories").pluck("name"), "Minuman"

    assert_difference([ "Product.count", "AuditLog.count" ], 1) do
      post api_v1_admin_products_url, params: { category_id: categories(:food).id, name: "Roti", sku: "roti-001", cost_price: 5000, selling_price: 9000, minimum_stock: 3, unit: "pcs", active: true }, as: :json
    end
    assert_response :created
    product = Product.find_by!(sku: "ROTI-001")

    get api_v1_admin_product_url(product)
    assert_response :success
    assert_equal "Makanan", response.parsed_body.dig("product", "category_name")

    patch api_v1_admin_product_url(product), params: { selling_price: 10000 }, as: :json
    assert_response :success
    assert_equal 10000, product.reload.selling_price

    assert_difference("Product.count", -1) { delete api_v1_admin_product_url(product) }
    assert_response :no_content
  end

  test "invalid product returns field errors" do
    post api_v1_admin_products_url, params: { name: "", sku: "", cost_price: -1 }, as: :json
    assert_response :unprocessable_content
    assert_api_error "VALIDATION_FAILED"
    assert response.parsed_body.dig("error", "details", "name").present?
  end

  test "member cannot access products" do
    sign_in_as(users(:two))
    get api_v1_admin_products_url
    assert_response :forbidden
  end
end
