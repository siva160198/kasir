class CashierShift < ApplicationRecord
  POS_VERIFICATION_LIFETIME = 12.hours

  belongs_to :user
  has_many :cash_movements, dependent: :restrict_with_error
  has_many :sale_refunds, dependent: :restrict_with_error
  has_many :sales, dependent: :restrict_with_error
  validates :shift_number, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[open closed] }
  validates :opening_cash, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :opening_note, :closing_note, length: { maximum: 500 }, allow_blank: true
  scope :open, -> { where(status: "open") }

  def pos_verified_for?(session)
    pos_verified_at.present? &&
      pos_verified_at > POS_VERIFICATION_LIFETIME.ago &&
      pos_verified_session_id == session&.id
  end
end
