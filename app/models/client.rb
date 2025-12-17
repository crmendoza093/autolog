class Client < ApplicationRecord
  belongs_to :shop
  has_many :vehicles, dependent: :destroy
  has_many :service_records, dependent: :destroy

  validates :name, presence: true
  validates :phone, format: { with: /\A\+?\d{10,15}\z/, allow_blank: true }

  scope :for_shop, ->(shop_id) { where(shop_id: shop_id) }
end
