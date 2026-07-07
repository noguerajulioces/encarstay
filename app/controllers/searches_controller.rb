class SearchesController < ApplicationController
  def show
    @search = Search.new(search_params)
    @results = @search.results
  end

  private
    def search_params
      params.fetch(:search, {}).permit(:check_in, :check_out, :guests)
    end
end
