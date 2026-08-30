class GoodsReceiptItem < ApplicationRecord
  belongs_to :goods_receipt; belongs_to :purchase_order_item
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
