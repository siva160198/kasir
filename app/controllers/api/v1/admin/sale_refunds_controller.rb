module Api::V1::Admin
  class SaleRefundsController < ApplicationController
    def create
      sale = Sale.includes(:sale_items, :payments, :sale_refunds).find(params[:sale_id])
      authorize sale, :refund?
      shift = Current.user.cashier_shifts.open.first
      return render_api_error("SHIFT_REQUIRED", status: :unprocessable_content) unless shift

      refund = create_refund!(sale, shift)
      render json: { refund: refund_json(refund) }, status: :created
    rescue ActiveRecord::RecordInvalid => error
      render_validation_error(error.record)
    end

    def approve
      refund = SaleRefund.includes(sale_refund_items: { sale_item: :product }).find(params[:id])
      authorize refund, :approve?
      apply_refund!(refund)
      render json: { refund: refund_json(refund.reload) }
    rescue ActiveRecord::RecordInvalid => error
      render_validation_error(error.record)
    end

    def reject
      refund = SaleRefund.find(params[:id])
      authorize refund, :reject?
      refund.with_lock do
        ensure_pending!(refund)
        refund.update!(status: "rejected", reviewed_by: Current.user, reviewed_at: Time.current, review_note: params[:review_note].to_s.strip.presence)
      end
      render json: { refund: refund_json(refund) }
    rescue ActiveRecord::RecordInvalid => error
      render_validation_error(error.record)
    end

    private
      def create_refund!(sale, shift)
        type = params[:refund_type] == "void" ? "void" : "partial"
        rows = requested_rows(sale, type)
        reason = params[:reason].to_s.strip
        refund = SaleRefund.new(sale: sale, cashier_shift: shift, requested_by: Current.user, refund_type: type, refund_number: "RTR-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}", reason: reason, total: 1)
        refund.errors.add(:reason, :blank) if reason.blank?
        refund.errors.add(:items, :blank) if rows.empty?
        raise ActiveRecord::RecordInvalid.new(refund) if refund.errors.any?

        SaleRefund.transaction do
          sale.lock!
          reserved = SaleRefundItem.joins(:sale_refund).where(sale_refunds: { sale_id: sale.id, status: %w[pending approved] }).group(:sale_item_id).sum(:quantity)
          total = rows.sum do |row|
            item = sale.sale_items.find { |candidate| candidate.id == row[:sale_item_id].to_i }
            quantity = row[:quantity].to_i
            if item.nil? || quantity <= 0 || quantity > item.quantity - reserved.fetch(item&.id, 0)
              refund.errors.add(:items, :invalid)
              raise ActiveRecord::RecordInvalid.new(refund)
            end
            quantity * item.unit_price
          end
          refund.total = total
          refund.save!
          rows.each do |row|
            item = sale.sale_items.find { |candidate| candidate.id == row[:sale_item_id].to_i }
            quantity = row[:quantity].to_i
            refund.sale_refund_items.create!(sale_item: item, quantity: quantity, unit_price: item.unit_price, subtotal: quantity * item.unit_price)
          end
          refund
        end
      end

      def requested_rows(sale, type)
        return sale.sale_items.map { |item| { sale_item_id: item.id, quantity: item.quantity } } if type == "void"
        Array(params[:items]).map { |row| row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h.symbolize_keys : row.symbolize_keys }.select { |row| row[:quantity].to_i.positive? }
      end

      def apply_refund!(refund)
        SaleRefund.transaction do
          refund.lock!
          ensure_pending!(refund)
          unless refund.cashier_shift.status == "open"
            refund.errors.add(:cashier_shift, "harus masih aktif")
            raise ActiveRecord::RecordInvalid.new(refund)
          end

          refund.sale_refund_items.each do |refund_item|
            product = refund_item.sale_item.product.lock!
            before = product.current_stock
            product.update!(current_stock: before + refund_item.quantity)
            StockMovement.create!(product: product, user: Current.user, movement_type: "refund", quantity: refund_item.quantity, stock_before: before, stock_after: product.current_stock, note: "Retur #{refund.refund_number}", reference_type: "SaleRefund", reference_id: refund.id)
          end
          if refund.sale.payments.first&.payment_method == "cash"
            CashMovement.create!(cashier_shift: refund.cashier_shift, user: Current.user, movement_type: "refund", amount: -refund.total, note: "Retur #{refund.refund_number}", reference_type: "SaleRefund", reference_id: refund.id)
          end
          refund.update!(status: "approved", reviewed_by: Current.user, reviewed_at: Time.current, review_note: params[:review_note].to_s.strip.presence)
          update_sale_status!(refund.sale)
        end
      end

      def update_sale_status!(sale)
        returned = SaleRefundItem.joins(:sale_refund).where(sale_refunds: { sale_id: sale.id, status: "approved" }).sum(:quantity)
        sold = sale.sale_items.sum(:quantity)
        full_refund = returned >= sold
        voided = full_refund && sale.sale_refunds.where(status: "approved", refund_type: "void").exists?
        sale.update_columns(status: voided ? "voided" : (full_refund ? "refunded" : "partially_refunded"), updated_at: Time.current)
      end

      def ensure_pending!(refund)
        return if refund.status == "pending"
        refund.errors.add(:status, "sudah ditinjau")
        raise ActiveRecord::RecordInvalid.new(refund)
      end

      def refund_json(refund)
        refund.as_json(only: %i[id refund_number refund_type status total reason review_note created_at reviewed_at]).merge(
          requested_by: refund.requested_by.email_address,
          reviewed_by: refund.reviewed_by&.email_address,
          payment_method: refund.sale.payments.first&.payment_method,
          items: refund.sale_refund_items.includes(:sale_item).map { |item| item.as_json(only: %i[id sale_item_id quantity unit_price subtotal]).merge(product_name: item.sale_item.product_name) }
        )
      end
  end
end
