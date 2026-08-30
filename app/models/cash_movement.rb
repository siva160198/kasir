class CashMovement < ApplicationRecord
  CATEGORIES = %w[additional_capital operational store_supplies cash_withdrawal other].freeze
  belongs_to :cashier_shift
  belongs_to :user
  validates :movement_type, inclusion: { in: %w[opening cash_in cash_out sale refund closing] }
  validates :amount, numericality: { only_integer: true }
  validates :note, presence: true, length: { maximum: 500 }
  validates :category, inclusion: { in: CATEGORIES }, allow_nil: true
  before_update { throw(:abort) }; before_destroy { throw(:abort) }
end
