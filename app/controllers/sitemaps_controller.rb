class SitemapsController < ApplicationController
  def show
    @properties = Property.active.alphabetically
  end
end
