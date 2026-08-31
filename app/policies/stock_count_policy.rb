class StockCountPolicy < ApplicationPolicy
  def index? = user&.can?("stock_counts.view")
  def show? = index?
  def create? = user&.can?("stock_counts.create")
  def update? = user&.can?("stock_counts.update") && record.status == "draft"
  def finalize? = update?
  class Scope < ApplicationPolicy::Scope
    def resolve = user&.can?("stock_counts.view") ? scope.all : scope.none
  end
end
