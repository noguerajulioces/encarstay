class EventsController < ApplicationController
  def index
    @categories = Category.ordered
    @active_category = params[:category]
    # Sin eventos publicados, el índice se muestra como "próximamente" y
    # esconde buscador y categorías.
    @events_exist = GuideEntry.events.published.exists?
    @events = GuideEntry.events.published.upcoming
    @events = @events.in_category(@active_category) if @active_category.present?
    @events = search(@events, params[:q]) if params[:q].present?
  end

  def show
    @event = GuideEntry.events.published.find_by!(slug: params[:slug])
    @properties = @event.properties_to_promote.limit(3)
    @related = GuideEntry.events.published.upcoming.where.not(id: @event.id).limit(3)
  end

  private
    def search(scope, query)
      loc = I18n.available_locales.include?(I18n.locale) ? I18n.locale : I18n.default_locale
      scope.where("title_#{loc} LIKE :q OR summary_#{loc} LIKE :q", q: "%#{query}%")
    end
end
