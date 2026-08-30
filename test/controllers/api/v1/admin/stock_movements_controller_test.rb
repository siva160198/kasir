require "test_helper"

class Api::V1::Admin::StockMovementsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "admin views inventory and adjusts stock atomically" do
    product = products(:coffee)
    product.update!(current_stock: 10)
    get api_v1_admin_inventory_index_url
    assert_response :success
    assert_equal 10, response.parsed_body.fetch("inventory").find { |row| row["id"] == product.id }.fetch("current_stock")

    assert_difference([ "StockMovement.count", "AuditLog.count" ], 1) do
      post api_v1_admin_stock_movements_url, params: { product_id: product.id, movement_type: "damaged", quantity: 3, note: "Kemasan rusak" }, as: :json
    end
    assert_response :created
    assert_equal 7, product.reload.current_stock

    get api_v1_admin_stock_movements_url
    assert_response :success
    assert_equal "Kemasan rusak", response.parsed_body.fetch("stock_movements").first.fetch("note")
  end

  test "adjustment cannot make stock negative" do
    product = products(:coffee)
    product.update!(current_stock: 2)
    assert_no_difference("StockMovement.count") do
      post api_v1_admin_stock_movements_url, params: { product_id: product.id, movement_type: "lost", quantity: 3, note: "Hilang" }, as: :json
    end
    assert_response :unprocessable_content
    assert_api_error "VALIDATION_FAILED"
    assert_equal 2, product.reload.current_stock
  end

  test "member cannot access inventory" do
    sign_in_as(users(:two)); get api_v1_admin_inventory_index_url; assert_response :forbidden
  end

  test "stock alerts create purchase drafts grouped by preferred supplier" do
    supplier = Supplier.create!(name: "Supplier Alert")
    product = products(:coffee)
    product.update!(current_stock: 0, minimum_stock: 8, preferred_supplier: supplier)

    get "/api/v1/admin/inventory/alerts"
    assert_response :success
    assert_operator response.parsed_body["count"], :>=, 1

    assert_difference("PurchaseOrder.count", 1) do
      post "/api/v1/admin/inventory/create_drafts", params: { product_ids: [ product.id ], days: 7 }, as: :json
    end
    assert_response :created
    order = PurchaseOrder.order(:id).last
    assert_equal "draft", order.status
    assert_equal supplier, order.supplier
    assert_equal 8, order.purchase_order_items.first.quantity
  end
end
