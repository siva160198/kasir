class Supplier < ApplicationRecord
  scope :active, -> { where(active: true) }
  has_many :purchase_orders, dependent: :restrict_with_error
  has_many :preferred_products, class_name: "Product", foreign_key: :preferred_supplier_id, dependent: :nullify
  normalizes :name, with: ->(value) { value.strip.gsub(/\s+/, " ") }
  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 160 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, :contact_name, length: { maximum: 100 }, allow_blank: true
  validates :address, length: { maximum: 500 }, allow_blank: true
end
