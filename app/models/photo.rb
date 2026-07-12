class Photo < ApplicationRecord
  belongs_to :property
  has_one_attached :image do |attachable|
    attachable.variant :card_small,
      resize_to_fill: [ 320, 320 ], format: :webp, saver: { quality: 76 }, preprocessed: true
    attachable.variant :card,
      resize_to_fill: [ 640, 640 ], format: :webp, saver: { quality: 78 }, preprocessed: true
    attachable.variant :preview,
      resize_to_fill: [ 1200, 900 ], format: :webp, saver: { quality: 80 }, preprocessed: true
    attachable.variant :gallery,
      resize_to_limit: [ 1600, 1600 ], format: :webp, saver: { quality: 82 }, preprocessed: true
  end

  scope :ordered, -> { order(:position) }
end
