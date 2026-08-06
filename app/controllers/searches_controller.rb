class SearchesController < ApplicationController
  # /search fue la página de resultados; ese trabajo hoy lo hace el comparador
  # de /properties con más contexto. Redirigimos preservando fechas y huéspedes.
  def show
    redirect_to properties_path(search: search_params.to_h.presence, anchor: "comparador"),
      status: :moved_permanently
  end

  private
    def search_params
      params.fetch(:search, {}).permit(:check_in, :check_out, :guests)
    end
end
