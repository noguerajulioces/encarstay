# Exposes a money column stored in minor units (× 100) as an accessor in the
# currency's major unit, for friendly admin form input. `monetize :base_price`
# reads/writes the `base_price_cents` column.
module Monetizable
  extend ActiveSupport::Concern

  class_methods do
    def monetize(*names)
      names.each do |name|
        define_method(name) do
          cents = self["#{name}_cents"]
          cents && ((cents % 100).zero? ? cents / 100 : cents / 100.0)
        end

        define_method("#{name}=") do |value|
          self["#{name}_cents"] = (value.to_s.tr(",", ".").to_f * 100).round
        end
      end
    end
  end
end
