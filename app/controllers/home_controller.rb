class HomeController < ApplicationController
  def index
    @search = Search.new
    @properties = Property.active.with_attached_photos.alphabetically
    @categories = Category.ordered
  end
end
