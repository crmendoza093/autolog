class AnalyticsEvent < ApplicationRecord
  belongs_to :shop

  EVENT_TYPES = %w[
    service_registered
    llm_call
    message_sent
    confirmation_accepted
    confirmation_rejected
    suggestion_used
  ].freeze

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }

  scope :for_shop, ->(shop_id) { where(shop_id: shop_id) }
  scope :for_type, ->(type) { where(event_type: type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
end
