class CustomerPolicy < ApplicationPolicy
  def index? = user&.can?("customers.view")
  def show? = index?
  def create? = user&.can?("customers.create")
  def update? = user&.can?("customers.update")
  def destroy? = user&.can?("customers.delete")
  class Scope < ApplicationPolicy::Scope
    def resolve = user&.can?("customers.view") ? scope.all : scope.none
  end
end
