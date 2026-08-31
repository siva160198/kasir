require "test_helper"
class Api::V1::Admin::SalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one)); @product = products(:coffee); @product.update!(current_stock: 10)
    @shift = CashierShift.create!(user: users(:one), shift_number: "SFT-SALE", opened_at: Time.current, opening_cash: 100_000)
    @shift.update!(pos_verified_at: Time.current, pos_verified_session_id: users(:one).sessions.order(:id).last.id)
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
  test "rejects checkout when the shift has not verified POS access" do
    @shift.update!(pos_verified_at: nil, pos_verified_session_id: nil)
    post api_v1_admin_sales_url, params: { client_token: SecureRandom.uuid, received_amount: 50_000, items: [ { product_id: @product.id, quantity: 1 } ] }, as: :json
    assert_response :unauthorized
    assert_api_error "POS_VERIFICATION_REQUIRED"
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

  test "checkout applies promotion and awards customer points" do
    customer = Customer.create!(customer_number: "CUS-TEST", name: "Member Test", member: true)
    promotion = Promotion.create!(name: "Diskon Test", code: "SAVE10", discount_type: "percentage", value: 10, minimum_purchase: 20_000, starts_at: 1.day.ago, ends_at: 1.day.from_now)

    post api_v1_admin_sales_url, params: { client_token: SecureRandom.uuid, received_amount: 50_000, customer_id: customer.id, promotion_code: promotion.code, items: [ { product_id: @product.id, quantity: 2 } ] }, as: :json
    assert_response :created
    sale = Sale.find(response.parsed_body.dig("sale", "id"))
    assert_equal 3_000, sale.discount
    assert_equal 27_000, sale.total
    assert_equal customer, sale.customer
    assert_equal promotion, sale.promotion
    assert_equal 2, customer.reload.points
    assert_equal 1, promotion.reload.usage_count
  end

  test "checkout rejects an unavailable promotion" do
    promotion = Promotion.create!(name: "Expired", code: "EXPIRED", discount_type: "fixed", value: 5_000, starts_at: 2.days.ago, ends_at: 1.day.ago)
    assert_no_difference("Sale.count") do
      post api_v1_admin_sales_url, params: { client_token: SecureRandom.uuid, received_amount: 50_000, promotion_code: promotion.code, items: [ { product_id: @product.id, quantity: 1 } ] }, as: :json
    end
    assert_response :unprocessable_content
    assert_api_error "VALIDATION_FAILED"
  end

  test "checkout supports item discount and split payment" do
    post api_v1_admin_sales_url, params: {
      client_token: SecureRandom.uuid,
      items: [ { product_id: @product.id, quantity: 2, discount: 3_000 } ],
      payments: [
        { payment_method: "cash", amount: 10_000, received_amount: 10_000 },
        { payment_method: "qris", amount: 17_000, reference_number: "QR-SPLIT" }
      ]
    }, as: :json
    assert_response :created
    sale = Sale.find(response.parsed_body.dig("sale", "id"))
    assert_equal 30_000, sale.subtotal
    assert_equal 3_000, sale.discount
    assert_equal 27_000, sale.total
    assert_equal 2, sale.payments.count
    assert_equal 3_000, sale.sale_items.first.discount
    assert_equal 10_000, CashMovement.order(:id).last.amount
  end

  test "split payment must exactly match transaction total" do
    assert_no_difference([ "Sale.count", "StockMovement.count" ]) do
      post api_v1_admin_sales_url, params: { client_token: SecureRandom.uuid, items: [ { product_id: @product.id, quantity: 1 } ], payments: [ { payment_method: "cash", amount: 10_000, received_amount: 10_000 } ] }, as: :json
    end
    assert_response :unprocessable_content
    assert_api_error "VALIDATION_FAILED"
    assert_equal 10, @product.reload.current_stock
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
