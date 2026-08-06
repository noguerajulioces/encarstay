class HomeController < ApplicationController
  def index
    # Mismo orden que el comparador (capacidad ascendente) para que la vitrina
    # y /properties cuenten la misma historia.
    @properties = Property.active.with_attached_photos.order(:capacity, :name)
    @categories = Category.ordered
  end
end
