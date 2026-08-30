class SaleRefundItem < ApplicationRecord
  belongs_to :sale_refund
  belongs_to :sale_item
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, :subtotal, numericality: { only_integer: true, greater_than: 0 }
end
