class PropertiesController < ApplicationController
  def index
    @search = Search.new(search_params)

    # De menor a mayor capacidad: la tabla cuenta "de 3 a 7 huéspedes" de un vistazo.
    # Las distancias por calle viven en la fila (bin/rails distances:refresh).
    properties = Property.active.with_attached_photos.includes(:amenities).order(:capacity, :name)

    @comparison = properties.map do |property|
      {
        property: property,
        amenity_keys: property.amenities.map(&:key),
        fits: !@search.valid_range? || property.capacity >= @search.guests.to_i,
        available: (property.available?(@search.check_in, @search.check_out) if @search.valid_range?),
        quote: (property.quote(@search.check_in, @search.check_out) if @search.valid_range?)
      }
    end
  end

  def show
    @property = Property.active.with_attached_photos.find_by!(slug: params[:slug])
    @check_in = parse_date(params[:check_in])
    @check_out = parse_date(params[:check_out])
    @guests = params[:guests].presence || 2
    @quote = @property.quote(@check_in, @check_out)
    @available = @quote.valid? && @property.available?(@check_in, @check_out)
    @occupied_dates = @property.occupied_dates
    @min_nights_overrides = @property.min_nights_overrides
    @reviews = @property.reviews.approved.recent
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

  private
    def search_params
      params.fetch(:search, {}).permit(:check_in, :check_out, :guests)
    end
end
