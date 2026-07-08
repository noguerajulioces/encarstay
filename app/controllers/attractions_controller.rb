class AttractionsController < ApplicationController
  def index
    @categories = Category.ordered
    @active_category = params[:category]
    @attractions = GuideEntry.attractions.published.ordered
    @attractions = @attractions.in_category(@active_category) if @active_category.present?
    @attractions = search(@attractions, params[:q]) if params[:q].present?
  end

  def show
    @attraction = GuideEntry.attractions.published.find_by!(slug: params[:slug])
    @properties = @attraction.properties_to_promote.limit(3)
    @related = GuideEntry.attractions.published.ordered.where.not(id: @attraction.id).limit(3)
  end

  private
    def search(scope, query)
      loc = I18n.available_locales.include?(I18n.locale) ? I18n.locale : I18n.default_locale
      scope.where("title_#{loc} LIKE :q OR summary_#{loc} LIKE :q", q: "%#{query}%")
    end
end
