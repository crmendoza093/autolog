class Conversation < ApplicationRecord
  belongs_to :shop

  STATES = %w[idle awaiting_confirmation awaiting_correction].freeze

  validates :state, inclusion: { in: STATES }

  scope :active, -> { where.not(state: "idle") }
  scope :stale, -> { where("last_activity_at < ?", 30.minutes.ago) }

  # Add message to conversation
  def add_message(role:, content:, action: nil)
    self.payload ||= {}
    self.payload["messages"] ||= []

    self.payload["messages"] << {
      "role" => role,
      "content" => content,
      "action" => action,
      "timestamp" => Time.current.iso8601
    }

    save!
  end

  # Get today's messages
  def messages_today
    return [] unless payload.present? && payload["messages"].present?
    return [] unless last_activity_at.present?

    # Only show messages if conversation was active today
    return [] unless last_activity_at >= Time.current.beginning_of_day

    payload["messages"]
  end

  # Clear messages (keep service data)
  def clear_messages
    return unless payload.present?

    service_data = payload.except("messages")
    self.payload = service_data.merge("messages" => [])
    save!
  end

  def update_state!(new_state, data = {})
    self.payload ||= {}
    self.payload.merge!(data)
    update!(
      state: new_state,
      payload: payload,
      last_activity_at: Time.current
    )
  end

  def reset!
    # Keep messages, only reset service data and state
    messages = payload&.[]("messages") || []
    update!(
      state: "idle",
      payload: { "messages" => messages },
      last_activity_at: Time.current
    )
  end

  def pending_data
    payload.with_indifferent_access.except(:messages)
  end
end
