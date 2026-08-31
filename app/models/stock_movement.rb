class StockMovement < ApplicationRecord
  TYPES = %w[initial adjustment_in adjustment_out damaged lost internal_use sale refund purchase stock_opname].freeze
  belongs_to :product
  belongs_to :user
  validates :movement_type, inclusion: { in: TYPES }
  validates :quantity, numericality: { only_integer: true, other_than: 0 }
  validates :stock_before, :stock_after, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :note, presence: true, length: { maximum: 500 }
  before_update { throw(:abort) }
  before_destroy { throw(:abort) }
end
