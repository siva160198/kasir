class SalePolicy < ApplicationPolicy
  def index? = user&.can?("sales.view_all") || user&.can?("sales.view_own")
  def create? = user&.can?("sales.create")
  def catalog? = create?
  def show? = user&.can?("sales.view_all") || (user&.can?("sales.view_own") && record.user_id == user.id)
  def refund? = show? && user&.can?("sales.refund_create")
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.can?("sales.view_all")
      user&.can?("sales.view_own") ? scope.where(user: user) : scope.none
    end
  end
end
