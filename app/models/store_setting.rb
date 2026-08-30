class StoreSetting < ApplicationRecord
  has_one_attached :logo
  validates :store_name, presence: true, length: { maximum: 160 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :currency, inclusion: { in: %w[IDR] }
  validates :tax_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :rounding_unit, inclusion: { in: [ 1, 100, 500, 1000 ] }
  validates :receipt_width, inclusion: { in: [ 58, 80 ] }
  validates :printer_copies, numericality: { only_integer: true, in: 1..5 }
  validates :address, :receipt_header, :receipt_footer, length: { maximum: 500 }, allow_blank: true
  validate :acceptable_logo

  def self.current = first_or_create!

  private
    def acceptable_logo
      return unless logo.attached?
      errors.add(:logo, :invalid) unless %w[image/png image/jpeg image/webp].include?(logo.blob.content_type)
      errors.add(:logo, :too_large) if logo.blob.byte_size > 1.megabyte
    end
end
