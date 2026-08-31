class ExpensePolicy < ApplicationPolicy
  def index? = user&.can?("expenses.view")
  def show? = index?
  def create? = user&.can?("expenses.create")
  def update? = user&.can?("expenses.update")
  def destroy? = user&.can?("expenses.delete")
  class Scope < ApplicationPolicy::Scope
    def resolve = user&.can?("expenses.view") ? scope.all : scope.none
  end
end
