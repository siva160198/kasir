class CashierShiftPolicy < ApplicationPolicy
  def index? = user&.can?("cashier_shifts.view_all") || user&.can?("cashier_shifts.view_own")
  def show? = index?
  def create? = user&.can?("cashier_shifts.manage_own")
  def update? = create? && record.user_id == user.id
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.can?("cashier_shifts.view_all")
      user&.can?("cashier_shifts.view_own") ? scope.where(user: user) : scope.none
    end
  end
end
