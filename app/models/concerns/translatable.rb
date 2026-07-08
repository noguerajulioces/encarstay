# Locale-aware content backed by per-locale columns (e.g. title_es, title_en,
# title_pt). `translates :title` defines a `title` reader that returns the value
# for the current locale, falling back to the default locale when it's blank.
# Chosen over a translations gem for simplicity: three fixed locales, small catalog.
module Translatable
  extend ActiveSupport::Concern

  class_methods do
    def translates(*attributes)
      attributes.each do |attribute|
        define_method(attribute) do
          self["#{attribute}_#{I18n.locale}"].presence || self["#{attribute}_#{I18n.default_locale}"]
        end
      end
    end
  end
end
