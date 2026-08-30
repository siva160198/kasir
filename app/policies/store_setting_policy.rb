class StoreSettingPolicy < ApplicationPolicy
  def show? = user&.can?("store_settings.manage")
  def update? = show?
end
