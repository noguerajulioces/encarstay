class HomeController < ApplicationController
  def index
    @search = Search.new
    @properties = Property.active.alphabetically
  end
end
