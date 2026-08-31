require "test_helper"
class Api::V1::Admin::CashierShiftsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "returns the current shift without requiring a current policy method" do
    get current_api_v1_admin_cashier_shifts_url
    assert_response :success
    assert_nil response.parsed_body["cashier_shift"]

    shift = CashierShift.create!(user: users(:one), shift_number: "SFT-CURRENT", opened_at: Time.current, opening_cash: 25_000)
    get current_api_v1_admin_cashier_shifts_url
    assert_response :success
    assert_equal shift.id, response.parsed_body.dig("cashier_shift", "id")
    assert_equal false, response.parsed_body.dig("cashier_shift", "pos_access_verified")

    shift.update!(pos_verified_at: Time.current, pos_verified_session_id: Session.order(:id).last.id)
    get current_api_v1_admin_cashier_shifts_url
    assert_equal true, response.parsed_body.dig("cashier_shift", "pos_access_verified")
  end

  test "opens and closes a shift" do
    post api_v1_admin_cashier_shifts_url, params: { opening_cash: 100_000, opening_note: "Mulai" }, as: :json
    assert_response :created
    shift = CashierShift.find(response.parsed_body.dig("cashier_shift", "id"))
    assert_equal 100_000, shift.opening_cash
    patch close_api_v1_admin_cashier_shift_url(shift), params: { actual_cash: 100_000 }, as: :json
    assert_response :success
    assert_equal "closed", shift.reload.status
    assert_equal 2, shift.cash_movements.count
  end
  test "difference requires closing note" do
    shift = CashierShift.create!(user: users(:one), shift_number: "SFT-TEST", opened_at: Time.current, opening_cash: 10_000)
    patch close_api_v1_admin_cashier_shift_url(shift), params: { actual_cash: 9_000 }, as: :json
    assert_response :unprocessable_content
    assert_equal "open", shift.reload.status
  end
  test "records cash in and cash out and prevents overdrawing drawer" do
    shift = CashierShift.create!(user: users(:one), shift_number: "SFT-CASH", opened_at: Time.current, opening_cash: 10_000)
    post cash_movement_api_v1_admin_cashier_shift_url(shift), params: { movement_type: "cash_in", amount: 5_000, category: "additional_capital", note: "Tambahan pecahan" }, as: :json
    assert_response :created
    assert_equal 15_000, response.parsed_body.dig("cashier_shift", "cash_summary", "expected_cash")

    post cash_movement_api_v1_admin_cashier_shift_url(shift), params: { movement_type: "cash_out", amount: 4_000, category: "operational", note: "Biaya parkir" }, as: :json
    assert_response :created
    assert_equal(-4_000, response.parsed_body.dig("cash_movement", "amount"))
    assert_equal 11_000, response.parsed_body.dig("cashier_shift", "cash_summary", "expected_cash")

    assert_no_difference("CashMovement.count") do
      post cash_movement_api_v1_admin_cashier_shift_url(shift), params: { movement_type: "cash_out", amount: 12_000, category: "operational", note: "Terlalu besar" }, as: :json
    end
    assert_response :unprocessable_content
  end
end
