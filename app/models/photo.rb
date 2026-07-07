class Photo < ApplicationRecord
  belongs_to :property
  has_one_attached :image

  scope :ordered, -> { order(:position) }
end
