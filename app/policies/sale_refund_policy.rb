class SaleRefundPolicy < ApplicationPolicy
  def create? = user&.can?("sales.refund_create")
  def approve? = user&.can?("sales.refund_review")
  def reject? = approve?
end
