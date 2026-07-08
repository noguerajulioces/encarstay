# The locale is an optional leading URL segment (/en, /pt); Spanish is unprefixed.
# Seeding a nil :locale into the routes' default url options keeps path helpers
# from grabbing the first positional argument (e.g. property_path(@property)) as
# the locale. Per-request, ApplicationController#default_url_options overrides
# this with the active locale so in-language links keep their prefix.
Rails.application.routes.default_url_options[:locale] = nil
