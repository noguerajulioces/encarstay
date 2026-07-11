# App-wide configuration editable from the admin. A single row holds every
# setting; `Setting.current` returns it, creating it on first access.
class Setting < ApplicationRecord
  def self.current
    first_or_create!
  end
end
