class Amenity < ApplicationRecord
  has_many :property_amenities, dependent: :destroy
  has_many :properties, through: :property_amenities

  scope :ordered, -> { order(:position, :key) }

  validates :key, presence: true, uniqueness: true

  # Human label, translated. Falls back to a humanised key if the locale lacks it.
  def label
    I18n.t("amenities.#{key}", default: key.humanize)
  end
end
