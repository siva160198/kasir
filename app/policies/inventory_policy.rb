class InventoryPolicy < ApplicationPolicy
  def index? = user&.can?("inventory.view")
  class Scope < ApplicationPolicy::Scope
    def resolve = user&.can?("inventory.view") ? scope.all : scope.none
  end
end
