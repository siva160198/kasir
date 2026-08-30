module Api
  module V1
    module Admin
      class DashboardController < ApplicationController
        def show
          authorize :dashboard, :show?

          period = %w[today week month].include?(params[:period]) ? params[:period] : "today"
          selected_range = period_range(period)
          comparison_range = previous_range(selected_range)
          selected_sales = Sale.where(completed_at: selected_range)
          comparison_sales = Sale.where(completed_at: comparison_range)
          selected_refunds = SaleRefund.where(status: "approved", reviewed_at: selected_range)
          comparison_refunds = SaleRefund.where(status: "approved", reviewed_at: comparison_range)
          selected_refund_items = SaleRefundItem.joins(:sale_refund, :sale_item)
            .where(sale_refunds: { id: selected_refunds.select(:id) })

          net_sales = selected_sales.sum(:total) - selected_refunds.sum(:total)
          comparison_net_sales = comparison_sales.sum(:total) - comparison_refunds.sum(:total)
          cost = SaleItem.where(sale_id: selected_sales.select(:id)).sum("quantity * cost_price")
          returned_cost = selected_refund_items.sum("sale_refund_items.quantity * sale_items.cost_price")
          transactions = selected_sales.count
          average_transaction = transactions.zero? ? 0 : net_sales / transactions

          period_sales = selected_sales.to_a
          period_refunds = selected_refunds.to_a

          payment_totals = Payment.where(sale_id: selected_sales.select(:id)).group(:payment_method).sum(:amount)
          selected_refunds.includes(sale: :payments).each do |refund|
            method = refund.sale.payments.first&.payment_method
            payment_totals[method] = payment_totals.fetch(method, 0) - refund.total if method
          end

          top_products = SaleItem.where(sale_id: period_sales.map(&:id))
            .group(:product_name)
            .pluck(:product_name, Arel.sql("SUM(quantity)"), Arel.sql("SUM(subtotal)"))
            .sort_by { |(_, quantity, revenue)| [ -quantity, -revenue ] }
            .first(5)

          low_stock = Product.active.where("current_stock <= minimum_stock")
            .order(Arel.sql("current_stock ASC, name ASC"))
            .limit(20)

          render json: {
            user: Current.user.as_json(only: %i[id email_address role first_name last_name]),
            generated_at: Time.current.iso8601,
            period: period,
            summary: {
              net_sales: net_sales,
              transactions: transactions,
              average_transaction: average_transaction,
              gross_profit: net_sales - (cost - returned_cost),
              sales_change: percentage_change(net_sales, comparison_net_sales)
            },
            weekly_sales: chart_series(period, period_sales, period_refunds),
            payments: Payment::METHODS.map { |method| { method: method, total: payment_totals.fetch(method, 0) } },
            top_products: top_products.map { |name, quantity, revenue| { name: name, quantity: quantity, revenue: revenue } },
            stock: {
              low_count: Product.active.where("current_stock <= minimum_stock").count,
              out_count: Product.active.where(current_stock: 0).count,
              items: low_stock.as_json(only: %i[id name sku current_stock minimum_stock unit])
            },
            shifts: {
              open_count: CashierShift.open.count,
              items: CashierShift.open.includes(:user).order(opened_at: :desc).limit(5).map do |shift|
                { id: shift.id, number: shift.shift_number, cashier: shift.user.full_name.presence || shift.user.email_address, opened_at: shift.opened_at }
              end
            },
            recent_sales: Sale.includes(:user, :payments).order(completed_at: :desc).limit(5).map do |sale|
              { id: sale.id, number: sale.sale_number, cashier: sale.user.full_name.presence || sale.user.email_address, total: sale.total, status: sale.status, payment_method: sale.payments.first&.payment_method, completed_at: sale.completed_at }
            end
          }
        end

        private
          def period_range(period)
            today = Date.current
            case period
            when "week" then (today - 6.days).beginning_of_day..today.end_of_day
            when "month" then today.beginning_of_month.beginning_of_day..today.end_of_day
            else today.beginning_of_day..today.end_of_day
            end
          end

          def previous_range(range)
            duration = range.end - range.begin
            previous_end = range.begin - 1.second
            (previous_end - duration)..previous_end
          end

          def chart_series(period, sales, refunds)
            if period == "today"
              sales_by_hour = sales.group_by { |sale| sale.completed_at.in_time_zone.hour }
              refunds_by_hour = refunds.group_by { |refund| refund.reviewed_at.in_time_zone.hour }
              return (8..20).map do |hour|
                { date: Date.current.iso8601, label: format("%02d.00", hour), net_sales: sales_by_hour.fetch(hour, []).sum(&:total) - refunds_by_hour.fetch(hour, []).sum(&:total), transactions: sales_by_hour.fetch(hour, []).size }
              end
            end

            dates = period == "month" ? (Date.current.beginning_of_month..Date.current).to_a : (Date.current - 6.days..Date.current).to_a
            sales_by_date = sales.group_by { |sale| sale.completed_at.in_time_zone.to_date }
            refunds_by_date = refunds.group_by { |refund| refund.reviewed_at.in_time_zone.to_date }
            dates.map do |date|
              { date: date.iso8601, label: period == "month" ? date.day.to_s : I18n.l(date, format: "%a"), net_sales: sales_by_date.fetch(date, []).sum(&:total) - refunds_by_date.fetch(date, []).sum(&:total), transactions: sales_by_date.fetch(date, []).size }
            end
          end

          def percentage_change(current, previous)
            return current.zero? ? 0.0 : 100.0 if previous.zero?

            (((current - previous).to_f / previous.abs) * 100).round(1)
          end
      end
    end
  end
end
