class Payment < ApplicationRecord
  belongs_to :sale
  METHODS = %w[cash qris transfer debit_card].freeze
  validates :payment_method, inclusion: { in: METHODS }
  validates :amount, :received_amount, :change_amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
