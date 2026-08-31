class SaleItem < ApplicationRecord
  belongs_to :sale; belongs_to :product
  has_many :sale_refund_items, dependent: :restrict_with_error
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :discount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
