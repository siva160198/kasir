class StockCountItem < ApplicationRecord
  belongs_to :stock_count
  belongs_to :product
  validates :system_stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :counted_stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :product_id, uniqueness: { scope: :stock_count_id }
end
