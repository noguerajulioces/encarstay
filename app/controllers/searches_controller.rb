class SearchesController < ApplicationController
  def show
    @search = Search.new(search_params)
    @results = @search.list

    # Map markers are date-independent: every geolocated stay and point of
    # interest, so the map works with or without a date range.
    @map_properties  = Property.active.where.not(latitude: nil, longitude: nil)
    @map_attractions = GuideEntry.attractions.published.where.not(latitude: nil, longitude: nil).ordered
    @map_events      = GuideEntry.events.published.upcoming.where.not(latitude: nil, longitude: nil)

    # Only categories that actually tag a geolocated POI become filter chips.
    poi_category_ids = (@map_attractions.map(&:category_id) + @map_events.map(&:category_id)).compact.uniq
    @poi_categories  = Category.where(id: poi_category_ids).ordered
  end

  private
    def search_params
      params.fetch(:search, {}).permit(:check_in, :check_out, :guests)
    end
end
