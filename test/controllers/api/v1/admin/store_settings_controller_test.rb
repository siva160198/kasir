require "test_helper"

class Api::V1::Admin::StoreSettingsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "updates store profile receipt and tax settings" do
    patch api_v1_admin_store_setting_url, params: { store_name: "Toko Bali", tax_rate: 11, prices_include_tax: false, rounding_unit: 500, receipt_width: 80, receipt_footer: "Suksma" }, as: :json
    assert_response :success
    setting = StoreSetting.current
    assert_equal "Toko Bali", setting.store_name
    assert_equal 11.to_d, setting.tax_rate
    assert_equal 80, setting.receipt_width
  end

  test "returns the attached store logo URL" do
    setting = StoreSetting.current
    setting.logo.attach(io: StringIO.new("fake png"), filename: "store.png", content_type: "image/png")

    get api_v1_admin_store_setting_url, as: :json

    assert_response :success
    assert_equal "/api/v1/store_profile/logo", response.parsed_body.dig("store_setting", "logo_url")

    get logo_api_v1_store_profile_url
    assert_response :success
    assert_equal "image/png", response.media_type
  end

  test "checkout applies configured tax and rounding" do
    StoreSetting.current.update!(tax_rate: 11, prices_include_tax: false, rounding_unit: 500)
    product = products(:coffee); product.update!(current_stock: 5)
    CashierShift.create!(user: users(:one), shift_number: "SFT-TAX", opened_at: Time.current, opening_cash: 0, pos_verified_at: Time.current, pos_verified_session_id: users(:one).sessions.order(:id).last.id)
    post api_v1_admin_sales_url, params: { client_token: SecureRandom.uuid, received_amount: 20_000, items: [ { product_id: product.id, quantity: 1 } ] }, as: :json
    assert_response :created
    assert_equal 1_650, response.parsed_body.dig("sale", "tax_amount")
    assert_equal 16_500, response.parsed_body.dig("sale", "total")
  end
end
