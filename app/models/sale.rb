class Sale < ApplicationRecord
  belongs_to :cashier_shift
  belongs_to :user
  has_many :sale_items, dependent: :restrict_with_error
  has_many :payments, dependent: :restrict_with_error
  has_many :sale_refunds, dependent: :restrict_with_error
  validates :sale_number, :client_token, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[completed partially_refunded refunded voided] }
  validates :subtotal, :discount, :tax_amount, :total, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rounding_amount, numericality: { only_integer: true }
  before_update { throw(:abort) }; before_destroy { throw(:abort) }
end
