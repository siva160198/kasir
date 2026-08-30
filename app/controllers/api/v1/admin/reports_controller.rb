require "csv"

module Api::V1::Admin
  class ReportsController < ApplicationController
    def show
      authorize :report, :show?
      render json: report_data
    end

    def export
      authorize :report, :export?
      data = report_data
      csv = CSV.generate do |rows|
        rows << [ "Laporan penjualan", data[:period][:from], data[:period][:to] ]
        rows << []
        rows << [ "Ringkasan", "Nilai" ]
        data[:summary].each { |key, value| rows << [ key.to_s, value ] }
        rows << []
        rows << [ "Tanggal", "Omzet bersih", "Transaksi" ]
        data[:daily].each { |day| rows << [ day[:date], day[:net_sales], day[:transactions] ] }
        rows << []
        rows << [ "Produk", "Jumlah bersih", "Omzet", "Laba" ]
        data[:products].each { |product| rows << [ product[:name], product[:quantity], product[:net_sales], product[:profit] ] }
      end
      send_data csv, filename: "laporan-#{data[:period][:from]}-#{data[:period][:to]}.csv", type: "text/csv; charset=utf-8"
    end

    private
      def report_data
        from, to = report_period
        sales = Sale.includes(:user, :payments, sale_items: :sale_refund_items).where(completed_at: from.beginning_of_day..to.end_of_day)
        sales = sales.where(user_id: params[:user_id]) if params[:user_id].present?
        sale_ids = sales.ids
        refunds = SaleRefund.where(sale_id: sale_ids, status: "approved").where(reviewed_at: from.beginning_of_day..to.end_of_day)
        refund_items = SaleRefundItem.joins(:sale_refund, :sale_item).where(sale_refunds: { id: refunds.select(:id) })

        gross_sales = sales.sum(:total)
        refund_total = refunds.sum(:total)
        gross_cost = SaleItem.where(sale_id: sale_ids).sum("quantity * cost_price")
        returned_cost = refund_items.sum("sale_refund_items.quantity * sale_items.cost_price")
        net_sales = gross_sales - refund_total
        profit = net_sales - (gross_cost - returned_cost)
        sales_by_day = sales.group_by { |sale| sale.completed_at.to_date }
        refunds_by_day = refunds.group_by { |refund| refund.reviewed_at.to_date }

        product_rows = SaleItem.where(sale_id: sale_ids).group(:product_name).pluck(:product_name, Arel.sql("SUM(quantity)"), Arel.sql("SUM(subtotal)"), Arel.sql("SUM(quantity * (unit_price - cost_price))")).to_h { |name, quantity, revenue, item_profit| [ name, { name: name, quantity: quantity, net_sales: revenue, profit: item_profit } ] }
        refund_items.group("sale_items.product_name").pluck("sale_items.product_name", Arel.sql("SUM(sale_refund_items.quantity)"), Arel.sql("SUM(sale_refund_items.subtotal)"), Arel.sql("SUM(sale_refund_items.quantity * (sale_items.unit_price - sale_items.cost_price))")).each do |name, quantity, revenue, item_profit|
          row = product_rows[name] || { name: name, quantity: 0, net_sales: 0, profit: 0 }
          row[:quantity] -= quantity; row[:net_sales] -= revenue; row[:profit] -= item_profit
          product_rows[name] = row
        end

        payment_totals = Payment.where(sale_id: sale_ids).group(:payment_method).sum(:amount)
        refunds.includes(sale: :payments).each { |refund| payment_totals[refund.sale.payments.first&.payment_method] = payment_totals.fetch(refund.sale.payments.first&.payment_method, 0) - refund.total }
        movements = CashMovement.where(created_at: from.beginning_of_day..to.end_of_day, movement_type: %w[cash_in cash_out])

        {
          period: { from: from.iso8601, to: to.iso8601 },
          summary: { gross_sales: gross_sales, refunds: refund_total, net_sales: net_sales, cost: gross_cost - returned_cost, gross_profit: profit, transactions: sales.count, average_transaction: sales.count.zero? ? 0 : net_sales / sales.count },
          daily: (from..to).map { |date| { date: date.iso8601, net_sales: sales_by_day.fetch(date, []).sum(&:total) - refunds_by_day.fetch(date, []).sum(&:total), transactions: sales_by_day.fetch(date, []).size } },
          products: product_rows.values.sort_by { |row| [ -row[:quantity], -row[:profit] ] }.first(10),
          payments: Payment::METHODS.index_with { |method| payment_totals.fetch(method, 0) },
          cash: { cash_in: movements.where(movement_type: "cash_in").sum(:amount), cash_out: movements.where(movement_type: "cash_out").sum(:amount).abs },
          cashiers: User.joins(:sales).distinct.order(:email_address).pluck(:id, :email_address).map { |id, email| { id: id, email: email } }
        }
      end

      def report_period
        to = Date.iso8601(params[:to].presence || Date.current.iso8601)
        from = Date.iso8601(params[:from].presence || (to - 29.days).iso8601)
        raise ArgumentError if from > to || (to - from).to_i > 366
        [ from, to ]
      rescue Date::Error, ArgumentError
        [ Date.current - 29.days, Date.current ]
      end
  end
end
