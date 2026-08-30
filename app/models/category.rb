class Category < ApplicationRecord
  has_many :products, dependent: :restrict_with_error

  normalizes :name, with: ->(value) { value.strip.gsub(/\s+/, " ") }

  validates :name, presence: true, length: { maximum: 120 }, uniqueness: { case_sensitive: false }
  validates :description, length: { maximum: 500 }, allow_blank: true
end
