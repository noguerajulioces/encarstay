class Post < ApplicationRecord
  include Translatable

  translates :title, :excerpt, :meta_description

  belongs_to :category, optional: true
  has_one_attached :cover_image

  # One Trix body per locale. Action Text keeps these as separate rich-text
  # records; #body picks the right one for the current locale.
  has_rich_text :body_es
  has_rich_text :body_en
  has_rich_text :body_pt

  scope :published, -> { where(published: true) }
  scope :featured,  -> { where(featured: true) }
  scope :recent,    -> { order(published_at: :desc, created_at: :desc) }
  scope :ordered,   -> { order(:position, published_at: :desc) }

  before_validation :set_slug, on: :create
  before_validation :ensure_published_at

  validates :title_es, presence: true
  validates :slug, presence: true, uniqueness: true

  # Rich-text body in the current locale, falling back to Spanish when the
  # requested translation is empty.
  def body
    localized = public_send("body_#{I18n.locale}")
    content = localized&.body
    content.present? ? localized : body_es
  end

  def to_param
    slug
  end

  private
    def set_slug
      self.slug = title_es.parameterize if slug.blank? && title_es.present?
    end

    def ensure_published_at
      self.published_at ||= Time.current if published?
    end
end
