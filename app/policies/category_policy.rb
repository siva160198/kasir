class CategoryPolicy < ApplicationPolicy
  def index? = user&.can?("categories.view")
  def show? = user&.can?("categories.view")
  def create? = user&.can?("categories.create")
  def update? = user&.can?("categories.update")
  def destroy? = user&.can?("categories.delete")

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.can?("categories.view") ? scope.all : scope.none
    end
  end
end
