class PurchaseOrderPolicy < ApplicationPolicy
  def index? = user&.can?("purchases.view"); def show? = index?
  def create? = user&.can?("purchases.create"); def update? = user&.can?("purchases.update")
  def receive? = update?; def cancel? = update?
  class Scope < ApplicationPolicy::Scope
    def resolve = user&.can?("purchases.view") ? scope.all : scope.none
  end
end
