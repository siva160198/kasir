class SupplierPolicy < ApplicationPolicy
  def index? = user&.can?("suppliers.view"); def show? = index?
  def create? = user&.can?("suppliers.create"); def update? = user&.can?("suppliers.update"); def destroy? = user&.can?("suppliers.delete")
  class Scope < ApplicationPolicy::Scope
    def resolve = user&.can?("suppliers.view") ? scope.all : scope.none
  end
end
