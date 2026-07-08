class SitemapsController < ApplicationController
  def show
    @properties = Property.active.alphabetically
    @events = GuideEntry.events.published.ordered
    @attractions = GuideEntry.attractions.published.ordered
    @posts = Post.published.recent
  end
end
