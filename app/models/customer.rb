class Customer < ApplicationRecord
  scope :active, -> { where(active: true) }
  has_many :sales, dependent: :restrict_with_error
  normalizes :name, with: ->(value) { value.strip.gsub(/\s+/, " ") }
  normalizes :phone, with: ->(value) { value.to_s.gsub(/\s+/, "").presence }
  normalizes :email, with: ->(value) { value.to_s.strip.downcase.presence }
  validates :customer_number, presence: true, uniqueness: true
  validates :name, presence: true, length: { maximum: 160 }
  validates :phone, length: { maximum: 30 }, uniqueness: true, allow_blank: true
  validates :email, length: { maximum: 255 }, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :points, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
