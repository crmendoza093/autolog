class ServiceRecord < ApplicationRecord
  belongs_to :shop
  belongs_to :client, optional: true
  belongs_to :vehicle, optional: true

  validates :service_name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :service_date, presence: true

  scope :recent, -> { order(service_date: :desc) }
  scope :today, -> { where(service_date: Date.today.all_day) }
  scope :this_week, -> { where(service_date: Date.today.beginning_of_week..Date.today.end_of_week) }
  scope :this_month, -> { where(service_date: Date.today.beginning_of_month..Date.today.end_of_month) }

  def client_name
    client&.name || "Sin cliente"
  end

  def vehicle_plate
    vehicle&.plate || "Sin placa"
  end

  after_create :track_analytics

  private

  def track_analytics
    shop.analytics_events.create!(
      event_type: "service_registered",
      metadata: {
        service_record_id: id,
        service_name: service_name,
        price: price,
        has_vehicle: vehicle_id.present?
      }
    )
  end
end
