class PurchaseOrderItem < ApplicationRecord
  belongs_to :purchase_order; belongs_to :product
  has_many :goods_receipt_items, dependent: :restrict_with_error
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :received_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :unit_cost, :subtotal, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
