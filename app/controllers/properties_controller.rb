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
    @min_nights_overrides = @property.min_nights_overrides
    @nearby_guide = @property.guide_entries.published.limit(4)
    @nearby_guide = GuideEntry.attractions.published.featured.ordered.limit(4) if @nearby_guide.empty?

    if @property.coordinates?
      @attraction_distances =
        GuideEntry.attractions.published
          .where.not(latitude: nil, longitude: nil)
          .map { |entry| [ entry, @property.distance_km_to(entry.latitude, entry.longitude) ] }
          .sort_by(&:last)
          .first(5)
    end
  end
end
