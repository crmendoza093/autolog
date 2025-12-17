class Shop < ApplicationRecord
  has_secure_password :pin, validations: false

  has_many :clients, dependent: :destroy
  has_many :service_records, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :services, dependent: :destroy
  has_many :analytics_events, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :pin, presence: true, length: { is: 4 }, format: { with: /\A\d{4}\z/ }

  def active_conversation
    # Find the most recent conversation (any state) or create a new one
    conversations.order(last_activity_at: :desc, created_at: :desc).first ||
      conversations.create!(state: "idle", payload: {})
  end
end
