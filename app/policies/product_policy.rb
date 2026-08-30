class ProductPolicy < ApplicationPolicy
  def index? = user&.can?("products.view")
  def show? = user&.can?("products.view")
  def create? = user&.can?("products.create")
  def update? = user&.can?("products.update")
  def destroy? = user&.can?("products.delete")

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.can?("products.view") ? scope.all : scope.none
    end
  end
end
