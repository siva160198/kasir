module Api::V1::Admin
  class CashierShiftsController < ApplicationController
    def index
      authorize CashierShift
      shifts, pagination = paginate_api(policy_scope(CashierShift), search_columns: %w[shift_number status], sortable_columns: %w[opened_at closed_at opening_cash cash_difference status], default_sort: :opened_at, default_direction: :desc)
      render json: { cashier_shifts: shifts.includes(:user).map { |s| shift_json(s) }, pagination: pagination }
    end
    def current
      authorize CashierShift, :show?
      shift = Current.user.cashier_shifts.open.first
      render json: { cashier_shift: shift && shift_json(shift) }
    end
    def create
      shift = Current.user.cashier_shifts.new(opening_cash: params[:opening_cash], opening_note: params[:opening_note], opened_at: Time.current, status: "open", shift_number: "SFT-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}")
      authorize shift
      CashierShift.transaction { shift.save!; CashMovement.create!(cashier_shift: shift, user: Current.user, movement_type: "opening", amount: shift.opening_cash, note: "Saldo awal shift") }
      AuditLog.record!(action: "cashier_shift.opened", actor: Current.user, auditable: shift, metadata: { opening_cash: shift.opening_cash }, request: request)
      render json: { cashier_shift: shift_json(shift) }, status: :created
    rescue ActiveRecord::RecordInvalid
      render_validation_error(shift)
    end
    def close
      shift = CashierShift.open.find(params[:id]); authorize shift, :update?
      actual = params[:actual_cash].to_i; expected = shift.opening_cash + shift.cash_movements.where.not(movement_type: "opening").sum(:amount); difference = actual - expected
      shift.assign_attributes(status: "closed", closed_at: Time.current, expected_cash: expected, actual_cash: actual, cash_difference: difference, closing_note: params[:closing_note])
      if difference != 0 && shift.closing_note.blank?
        shift.errors.add(:closing_note, :blank)
        return render_validation_error(shift)
      end
      return render_validation_error(shift) unless shift.valid?
      CashierShift.transaction { shift.save!; CashMovement.create!(cashier_shift: shift, user: Current.user, movement_type: "closing", amount: actual, note: shift.closing_note.presence || "Penutupan shift") }
      AuditLog.record!(action: "cashier_shift.closed", actor: Current.user, auditable: shift, metadata: { expected_cash: expected, actual_cash: actual, cash_difference: difference }, request: request)
      render json: { cashier_shift: shift_json(shift) }
    end
    def cash_movement
      shift = CashierShift.open.find(params[:id]); authorize shift, :update?
      type = params[:movement_type].to_s
      amount = params[:amount].to_i
      movement = shift.cash_movements.new(user: Current.user, movement_type: type, amount: type == "cash_out" ? -amount : amount, category: params[:category], note: params[:note])
      unless %w[cash_in cash_out].include?(type) && amount.positive?
        movement.errors.add(:amount, :invalid)
        return render_validation_error(movement)
      end
      if type == "cash_out" && amount > cash_summary(shift)[:expected_cash]
        movement.errors.add(:amount, "melebihi saldo kas")
        return render_validation_error(movement)
      end
      movement.save!
      render json: { cash_movement: movement_json(movement), cashier_shift: shift_json(shift.reload) }, status: :created
    rescue ActiveRecord::RecordInvalid => error
      render_validation_error(error.record)
    end
    private
      def cash_summary(shift)
        amounts = shift.cash_movements.where.not(movement_type: %w[opening closing]).group(:movement_type).sum(:amount)
        { opening_cash: shift.opening_cash, cash_sales: amounts.fetch("sale", 0), cash_refunds: amounts.fetch("refund", 0).abs, cash_in: amounts.fetch("cash_in", 0), cash_out: amounts.fetch("cash_out", 0).abs, expected_cash: shift.opening_cash + amounts.values.sum }
      end
      def movement_json(movement) = movement.as_json(only: %i[id movement_type amount category note created_at]).merge(user_email: movement.user.email_address)
      def shift_json(s)
        summary = cash_summary(s)
        s.as_json(only: %i[id shift_number status opened_at closed_at opening_cash expected_cash actual_cash cash_difference opening_note closing_note]).merge(pos_access_verified: s.pos_verified_for?(Current.session), user_email: s.user.email_address, transaction_count: s.sales.count, cash_sales: summary[:cash_sales], non_cash_sales: s.sales.joins(:payments).where.not(payments: { payment_method: "cash" }).sum(:total), refunds: summary[:cash_refunds], cash_summary: summary, cash_movements: s.cash_movements.where(movement_type: %w[cash_in cash_out]).includes(:user).order(created_at: :desc).map { |movement| movement_json(movement) })
      end
  end
end
