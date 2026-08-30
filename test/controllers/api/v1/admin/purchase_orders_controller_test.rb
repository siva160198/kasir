require "test_helper"

class Api::V1::Admin::PurchaseOrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
    @supplier = Supplier.create!(name: "PT Kopi Nusantara", active: true)
    @product = products(:coffee)
    @product.update!(current_stock: 5)
  end

  test "creates and partially receives purchase while updating stock and cost" do
    post api_v1_admin_purchase_orders_url, params: { supplier_id: @supplier.id, status: "ordered", payment_status: "unpaid", items: [ { product_id: @product.id, quantity: 10, unit_cost: 8_000 } ] }, as: :json
    assert_response :created
    order_id = response.parsed_body.dig("purchase_order", "id")
    item_id = response.parsed_body.dig("purchase_order", "items", 0, "id")

    assert_difference([ "GoodsReceipt.count", "StockMovement.count" ], 1) do
      post receive_api_v1_admin_purchase_order_url(order_id), params: { note: "Tahap pertama", items: [ { purchase_order_item_id: item_id, quantity: 4 } ] }, as: :json
    end
    assert_response :created
    assert_equal "partially_received", response.parsed_body.dig("purchase_order", "status")
    assert_equal 9, @product.reload.current_stock
    assert_equal 8_000, @product.cost_price

    post receive_api_v1_admin_purchase_order_url(order_id), params: { items: [ { purchase_order_item_id: item_id, quantity: 6 } ] }, as: :json
    assert_response :created
    assert_equal "completed", response.parsed_body.dig("purchase_order", "status")
    assert_equal 15, @product.reload.current_stock
  end

  test "rejects receiving more than the remaining quantity" do
    order = PurchaseOrder.create!(supplier: @supplier, user: users(:one), order_number: "PO-TEST", status: "ordered", payment_status: "unpaid", total: 8_000)
    item = order.purchase_order_items.create!(product: @product, quantity: 1, unit_cost: 8_000, subtotal: 8_000)
    assert_no_difference([ "GoodsReceipt.count", "StockMovement.count" ]) do
      post receive_api_v1_admin_purchase_order_url(order), params: { items: [ { purchase_order_item_id: item.id, quantity: 2 } ] }, as: :json
    end
    assert_response :unprocessable_content
    assert_equal 5, @product.reload.current_stock
  end
end
