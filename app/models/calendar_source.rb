class CalendarSource < ApplicationRecord
  belongs_to :property
  has_many :external_events, dependent: :destroy

  scope :active, -> { where(active: true) }

  validates :name, presence: true
  validates :ical_url, presence: true
end
