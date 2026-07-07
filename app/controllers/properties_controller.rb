class PropertiesController < ApplicationController
  def index
    @properties = Property.active.alphabetically
  end

  def show
    @property = Property.active.find_by!(slug: params[:slug])
    @check_in = parse_date(params[:check_in])
    @check_out = parse_date(params[:check_out])
    @guests = params[:guests].presence || 2
    @quote = @property.quote(@check_in, @check_out)
    @available = @quote.valid? && @property.available?(@check_in, @check_out)
    @occupied_dates = @property.occupied_dates
  end
end
