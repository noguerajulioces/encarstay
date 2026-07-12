class User < ApplicationRecord
  has_secure_password

  normalizes :email, with: ->(email) { email.strip.downcase }

  scope :alphabetically, -> { order(:name, :email) }

  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :password_confirmation, presence: true, if: -> { password.present? }

  def removable_by?(user)
    self != user
  end
end
