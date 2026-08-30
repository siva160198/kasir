class StockMovementPolicy < ApplicationPolicy
  def index? = user&.can?("stock_movements.view")
  def create? = user&.can?("stock_adjustments.create")
  def show? = create?
  class Scope < ApplicationPolicy::Scope
    def resolve = user&.can?("stock_movements.view") ? scope.all : scope.none
  end
end
