class Vehicle < ApplicationRecord
  belongs_to :client
  has_many :service_records, dependent: :nullify

  validates :plate, presence: true, uniqueness: true
  validates :plate, format: { with: /\A[A-Z0-9]{3,10}\z/i }

  before_validation :normalize_plate

  private

  def normalize_plate
    self.plate = plate&.upcase&.gsub(/\s+/, "")
  end
end
