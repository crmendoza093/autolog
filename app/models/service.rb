class Service < ApplicationRecord
  belongs_to :shop

  validates :name, presence: true
  validates :name, uniqueness: { scope: :shop_id, message: "ya existe en este taller" }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :popular, -> { order(usage_count: :desc) }

  # Increment usage count when service is used
  def increment_usage!
    increment!(:usage_count)
  end
end
