class PurchaseOrder < ApplicationRecord
  attr_accessor :items
  belongs_to :supplier; belongs_to :user
  has_many :purchase_order_items, dependent: :restrict_with_error
  has_many :goods_receipts, dependent: :restrict_with_error
  validates :order_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[draft ordered partially_received completed cancelled] }
  validates :payment_status, inclusion: { in: %w[unpaid partial paid] }
  validates :total, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :notes, length: { maximum: 500 }, allow_blank: true
end
