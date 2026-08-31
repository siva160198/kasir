class StockCount < ApplicationRecord
  STATUSES = %w[draft completed].freeze
  belongs_to :created_by, class_name: "User"
  belongs_to :finalized_by, class_name: "User", optional: true
  has_many :stock_count_items, dependent: :restrict_with_error
  validates :count_number, presence: true, uniqueness: true
  validates :counted_on, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :notes, length: { maximum: 500 }, allow_blank: true
end
