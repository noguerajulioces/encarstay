class ExternalEvent < ApplicationRecord
  include OccupiesDates
  occupies_dates from: :starts_on, to: :ends_on

  belongs_to :calendar_source

  validates :uid, presence: true
  validates :starts_on, :ends_on, presence: true
end
