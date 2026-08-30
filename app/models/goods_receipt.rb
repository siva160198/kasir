class GoodsReceipt < ApplicationRecord
  attr_accessor :items
  belongs_to :purchase_order; belongs_to :user
  has_many :goods_receipt_items, dependent: :restrict_with_error
  validates :receipt_number, presence: true, uniqueness: true
end
