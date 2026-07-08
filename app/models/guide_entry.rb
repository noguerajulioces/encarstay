class GuideEntry < ApplicationRecord
  include Translatable

  KINDS = %w[ attraction event ].freeze

  translates :title, :summary, :description, :schedule_note

  belongs_to :category, optional: true
  has_one_attached :cover_image
  has_many :property_recommendations, -> { order(:position) }, dependent: :destroy
  has_many :recommended_properties, through: :property_recommendations, source: :property

  scope :published,   -> { where(published: true) }
  scope :featured,    -> { where(featured: true) }
  scope :events,      -> { where(kind: "event") }
  scope :attractions, -> { where(kind: "attraction") }
  scope :ordered,     -> { order(:position, :title_es) }
  scope :in_category, ->(slug) { joins(:category).where(categories: { slug: slug }) }

  # Events that haven't finished yet (ongoing or in the future), soonest first.
  scope :upcoming, -> {
    where("ends_at >= :now OR (ends_at IS NULL AND starts_at >= :now)", now: Time.current)
      .order(:starts_at)
  }

  before_validation :set_slug, on: :create

  validates :kind, inclusion: { in: KINDS }
  validates :title_es, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :starts_at, presence: true, if: :event?

  def event?
    kind == "event"
  end

  def attraction?
    kind == "attraction"
  end

  # Curated stays to cross-promote on this entry, falling back to the whole
  # active catalogue when nothing has been curated yet.
  def properties_to_promote
    recommended_properties.active.presence || Property.active.alphabetically
  end

  def to_param
    slug
  end

  private
    def set_slug
      self.slug = title_es.parameterize if slug.blank? && title_es.present?
    end
end
