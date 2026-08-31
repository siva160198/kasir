class Expense < ApplicationRecord
  CATEGORIES = %w[utilities transport supplies meals maintenance rent salary marketing other].freeze
  PAYMENT_METHODS = %w[cash transfer debit_card].freeze

  belongs_to :user
  normalizes :description, with: ->(value) { value.strip.gsub(/\s+/, " ") }
  validates :expense_number, presence: true, uniqueness: true
  validates :expense_date, :description, presence: true
  validates :description, length: { maximum: 160 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :payment_method, inclusion: { in: PAYMENT_METHODS }
  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  validates :note, length: { maximum: 500 }, allow_blank: true
end
