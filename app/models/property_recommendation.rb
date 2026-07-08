class PropertyRecommendation < ApplicationRecord
  belongs_to :guide_entry
  belongs_to :property
end
