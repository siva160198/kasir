class SaleRefund < ApplicationRecord
  belongs_to :sale
  belongs_to :cashier_shift
  belongs_to :requested_by, class_name: "User"
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_many :sale_refund_items, dependent: :restrict_with_error

  validates :refund_number, presence: true, uniqueness: true
  validates :refund_type, inclusion: { in: %w[partial void] }
  validates :status, inclusion: { in: %w[pending approved rejected] }
  validates :reason, presence: true, length: { maximum: 500 }
  validates :total, numericality: { only_integer: true, greater_than: 0 }
end
