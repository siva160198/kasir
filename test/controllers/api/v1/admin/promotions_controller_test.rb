require "test_helper"

class Api::V1::Admin::PromotionsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "admin manages a promotion" do
    post api_v1_admin_promotions_url, params: { name: "Promo Test", code: "test10", discount_type: "percentage", value: 10, minimum_purchase: 20_000, starts_at: 1.day.ago, ends_at: 1.day.from_now, active: true }, as: :json
    assert_response :created
    promotion = Promotion.find(response.parsed_body.dig("promotion", "id"))
    assert_equal "TEST10", promotion.code

    patch api_v1_admin_promotion_url(promotion), params: { maximum_discount: 15_000 }, as: :json
    assert_response :success
    assert_equal 15_000, promotion.reload.maximum_discount

    assert_difference("Promotion.count", -1) { delete api_v1_admin_promotion_url(promotion), as: :json }
    assert_response :no_content
  end

  test "percentage cannot exceed one hundred" do
    post api_v1_admin_promotions_url, params: { name: "Invalid", code: "INVALID", discount_type: "percentage", value: 101, starts_at: 1.day.ago, ends_at: 1.day.from_now }, as: :json
    assert_response :unprocessable_content
    assert_api_error "VALIDATION_FAILED"
  end
end
