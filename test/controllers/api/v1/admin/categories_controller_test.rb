require "test_helper"

class Api::V1::Admin::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "admin manages categories with pagination and audit logs" do
    get api_v1_admin_categories_url, params: { search: "Makan" }
    assert_response :success
    assert_equal [ categories(:food).id ], response.parsed_body.fetch("categories").pluck("id")
    assert_equal %w[page per_page total total_pages], response.parsed_body.fetch("pagination").keys.sort

    assert_difference([ "Category.count", "AuditLog.count" ], 1) do
      post api_v1_admin_categories_url, params: { name: "Camilan", description: "Makanan ringan", active: true }, as: :json
    end
    assert_response :created
    category = Category.find_by!(name: "Camilan")

    get api_v1_admin_category_url(category)
    assert_response :success
    assert_equal 0, response.parsed_body.dig("category", "products_count")

    patch api_v1_admin_category_url(category), params: { name: "Snack" }, as: :json
    assert_response :success
    assert_equal "Snack", category.reload.name

    assert_difference("Category.count", -1) { delete api_v1_admin_category_url(category) }
    assert_response :no_content
  end

  test "category validation and product restriction use standard errors" do
    post api_v1_admin_categories_url, params: { name: "" }, as: :json
    assert_response :unprocessable_content
    assert_api_error "VALIDATION_FAILED"

    delete api_v1_admin_category_url(categories(:drink))
    assert_response :unprocessable_content
    assert_api_error "VALIDATION_FAILED"
  end

  test "unchanged category skips persistence and audit" do
    category = categories(:food)
    assert_no_difference("AuditLog.count") do
      patch api_v1_admin_category_url(category), params: { name: category.name, description: category.description, active: category.active }, as: :json
    end
    assert response.parsed_body["unchanged"]
  end

  test "member cannot access categories" do
    sign_in_as(users(:two))
    get api_v1_admin_categories_url
    assert_response :forbidden
  end
end
