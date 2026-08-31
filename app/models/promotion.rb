class Promotion < ApplicationRecord
  TYPES = %w[percentage fixed].freeze
  has_many :sales, dependent: :restrict_with_error
  normalizes :code, with: ->(value) { value.strip.upcase }
  validates :name, :code, :starts_at, :ends_at, presence: true
  validates :code, uniqueness: { case_sensitive: false }, length: { maximum: 40 }
  validates :discount_type, inclusion: { in: TYPES }
  validates :value, numericality: { only_integer: true, greater_than: 0 }
  validates :minimum_purchase, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :maximum_discount, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :usage_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :valid_period
  validate :valid_percentage

  scope :currently_active, -> { where(active: true).where("starts_at <= ? AND ends_at >= ?", Time.current, Time.current) }

  def available_for?(subtotal)
    active? && starts_at <= Time.current && ends_at >= Time.current && subtotal >= minimum_purchase && (usage_limit.nil? || usage_count < usage_limit)
  end

  def discount_for(subtotal)
    amount = discount_type == "percentage" ? (subtotal * value / 100.0).round : value
    [ amount, maximum_discount || amount, subtotal ].min
  end

  private
    def valid_period
      errors.add(:ends_at, :greater_than, count: starts_at) if starts_at && ends_at && ends_at <= starts_at
    end

    def valid_percentage
      errors.add(:value, :less_than_or_equal_to, count: 100) if discount_type == "percentage" && value.to_i > 100
    end
end
