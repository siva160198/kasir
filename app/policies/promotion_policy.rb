class PromotionPolicy < ApplicationPolicy
  def index? = user&.can?("promotions.view")
  def show? = index?
  def create? = user&.can?("promotions.create")
  def update? = user&.can?("promotions.update")
  def destroy? = user&.can?("promotions.delete")
  class Scope < ApplicationPolicy::Scope
    def resolve = user&.can?("promotions.view") ? scope.all : scope.none
  end
end
