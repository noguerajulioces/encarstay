class HomeController < ApplicationController
  def index
    @search = Search.new
    @properties = Property.active.with_attached_photos.alphabetically
    @categories = Category.ordered
    @featured_events = GuideEntry.events.published.featured.upcoming.limit(6)
    @featured_attractions = GuideEntry.attractions.published.featured.ordered.limit(6)
  end
end
