require "test_helper"
class Api::V1::Admin::SalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one)); @product = products(:coffee); @product.update!(current_stock: 10)
    @shift = CashierShift.create!(user: users(:one), shift_number: "SFT-SALE", opened_at: Time.current, opening_cash: 100_000)
  end
  test "cash checkout updates sale stock and shift cash atomically" do
    token = SecureRandom.uuid
    assert_difference([ "Sale.count", "StockMovement.count", "CashMovement.count" ], 1) do
      post api_v1_admin_sales_url, params: { client_token: token, received_amount: 50_000, items: [ { product_id: @product.id, quantity: 2 } ] }, as: :json
    end
    assert_response :created
    assert_equal 8, @product.reload.current_stock
    assert_equal 30_000, response.parsed_body.dig("sale", "total")
    assert_equal 20_000, response.parsed_body.dig("sale", "change_amount")
    assert_no_difference("Sale.count") { post api_v1_admin_sales_url, params: { client_token: token }, as: :json }
  end
  test "rejects checkout without shift" do
    @shift.destroy!
    post api_v1_admin_sales_url, params: { client_token: SecureRandom.uuid, received_amount: 50_000, items: [ { product_id: @product.id, quantity: 1 } ] }, as: :json
    assert_response :unprocessable_content
    assert_api_error "SHIFT_REQUIRED"
  end
  test "non cash checkout exposes detail without changing physical cash" do
    assert_no_difference("CashMovement.count") do
      post api_v1_admin_sales_url, params: { client_token: SecureRandom.uuid, payment_method: "qris", reference_number: "QR-123", items: [ { product_id: @product.id, quantity: 1 } ] }, as: :json
    end
    assert_response :created
    get api_v1_admin_sale_url(response.parsed_body.dig("sale", "id"))
    assert_response :success
    assert_equal "qris", response.parsed_body.dig("sale", "payment_method")
    assert_equal "QR-123", response.parsed_body.dig("sale", "reference_number")
    assert_equal "Kopi Susu", response.parsed_body.dig("sale", "items", 0, "product_name")
  end

  test "partial refund approval restores stock and adjusts cash" do
    post api_v1_admin_sales_url, params: { client_token: SecureRandom.uuid, received_amount: 50_000, items: [ { product_id: @product.id, quantity: 2 } ] }, as: :json
    sale_id = response.parsed_body.dig("sale", "id")
    sale_item = Sale.find(sale_id).sale_items.first

    assert_no_difference([ "StockMovement.count", "CashMovement.count" ]) do
      post api_v1_admin_sale_refunds_url(sale_id), params: { refund_type: "partial", reason: "Kemasan rusak", items: [ { sale_item_id: sale_item.id, quantity: 1 } ] }, as: :json
    end
    assert_response :created
    refund_id = response.parsed_body.dig("refund", "id")
    assert_equal "pending", response.parsed_body.dig("refund", "status")

    assert_difference([ "StockMovement.count", "CashMovement.count" ], 1) do
      patch approve_api_v1_admin_sale_refund_url(refund_id), params: { review_note: "Barang diterima" }, as: :json
    end
    assert_response :success
    assert_equal 9, @product.reload.current_stock
    assert_equal "partially_refunded", Sale.find(sale_id).status
    assert_equal(-15_000, CashMovement.order(:id).last.amount)
  end

  test "void request reserves every item and can be rejected without stock change" do
    post api_v1_admin_sales_url, params: { client_token: SecureRandom.uuid, received_amount: 50_000, items: [ { product_id: @product.id, quantity: 1 } ] }, as: :json
    sale_id = response.parsed_body.dig("sale", "id")
    post api_v1_admin_sale_refunds_url(sale_id), params: { refund_type: "void", reason: "Salah transaksi" }, as: :json
    refund_id = response.parsed_body.dig("refund", "id")

    assert_no_difference([ "StockMovement.count", "CashMovement.count" ]) do
      patch reject_api_v1_admin_sale_refund_url(refund_id), params: { review_note: "Ditolak" }, as: :json
    end
    assert_response :success
    assert_equal "rejected", SaleRefund.find(refund_id).status
    assert_equal 9, @product.reload.current_stock
  end
end
