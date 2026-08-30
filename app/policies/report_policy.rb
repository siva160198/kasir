class ReportPolicy < ApplicationPolicy
  def show? = user&.can?("reports.view")
  def export? = show?
end
