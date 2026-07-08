class Category < ApplicationRecord
  include Translatable

  translates :name

  has_many :guide_entries, dependent: :nullify

  scope :ordered, -> { order(:position, :name_es) }

  before_validation :set_slug, on: :create

  validates :name_es, presence: true
  validates :slug, presence: true, uniqueness: true

  def to_param
    slug
  end

  private
    def set_slug
      self.slug = name_es.parameterize if slug.blank? && name_es.present?
    end
end
