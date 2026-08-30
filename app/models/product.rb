class Product < ApplicationRecord
  scope :active, -> { where(active: true) }
  belongs_to :category
  belongs_to :preferred_supplier, class_name: "Supplier", optional: true
  has_many :stock_movements, dependent: :restrict_with_error
  has_many :purchase_order_items, dependent: :restrict_with_error

  normalizes :name, with: ->(value) { value.strip.gsub(/\s+/, " ") }
  normalizes :sku, with: ->(value) { value.strip.upcase }
  normalizes :barcode, with: ->(value) { value.to_s.strip.presence }
  normalizes :unit, with: ->(value) { value.strip.downcase }

  validates :name, presence: true, length: { maximum: 160 }
  validates :sku, presence: true, length: { maximum: 64 }, uniqueness: { case_sensitive: false }
  validates :barcode, length: { maximum: 64 }, uniqueness: true, allow_blank: true
  validates :cost_price, :selling_price, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :minimum_stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :current_stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :unit, presence: true, length: { maximum: 30 }
end
