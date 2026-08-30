class CashierShift < ApplicationRecord
  belongs_to :user
  has_many :cash_movements, dependent: :restrict_with_error
  has_many :sale_refunds, dependent: :restrict_with_error
  has_many :sales, dependent: :restrict_with_error
  validates :shift_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[open closed] }
  validates :opening_cash, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :opening_note, :closing_note, length: { maximum: 500 }, allow_blank: true
  scope :open, -> { where(status: "open") }
end
