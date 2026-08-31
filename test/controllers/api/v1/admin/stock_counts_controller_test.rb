require "test_helper"

class Api::V1::Admin::StockCountsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "admin counts and finalizes physical inventory" do
    product = products(:coffee)
    product.update!(active: true, current_stock: 10)
    post api_v1_admin_stock_counts_url, params: { counted_on: Date.current, notes: "Hitung bulanan" }, as: :json
    assert_response :created
    count = StockCount.find(response.parsed_body.dig("stock_count", "id"))
    item = count.stock_count_items.find_by!(product: product)

    patch "/api/v1/admin/stock_counts/#{count.id}/items/#{item.id}", params: { counted_stock: 8 }, as: :json
    assert_response :success
    assert_equal(-2, item.reload.difference)

    count.stock_count_items.where(counted_stock: nil).find_each { |row| row.update!(counted_stock: row.system_stock, difference: 0) }
    assert_difference("StockMovement.count", 1) do
      patch finalize_api_v1_admin_stock_count_url(count), params: {}, as: :json
    end
    assert_response :success
    assert_equal "completed", count.reload.status
    assert_equal 8, product.reload.current_stock
    assert_equal "stock_opname", StockMovement.order(:id).last.movement_type
  end

  test "cannot finalize an incomplete count" do
    post api_v1_admin_stock_counts_url, params: { counted_on: Date.current }, as: :json
    count = StockCount.find(response.parsed_body.dig("stock_count", "id"))
    patch finalize_api_v1_admin_stock_count_url(count), params: {}, as: :json
    assert_response :unprocessable_content
    assert_api_error "VALIDATION_FAILED"
    assert_equal "draft", count.reload.status
  end

  test "member cannot view stock counts" do
    sign_in_as(users(:two)); get api_v1_admin_stock_counts_url
    assert_response :forbidden
  end
end
