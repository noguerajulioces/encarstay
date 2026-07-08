class Admin::PropertyRecommendationsController < Admin::BaseController
  before_action :set_guide_entry

  def create
    if params[:property_id].present?
      @guide_entry.property_recommendations.find_or_create_by(property_id: params[:property_id]) do |rec|
        rec.position = @guide_entry.property_recommendations.count
      end
    end
    redirect_to edit_admin_guide_entry_path(@guide_entry), notice: "Alojamiento agregado."
  end

  def destroy
    @guide_entry.property_recommendations.find(params[:id]).destroy
    redirect_to edit_admin_guide_entry_path(@guide_entry), notice: "Alojamiento quitado."
  end

  private
    def set_guide_entry
      @guide_entry = GuideEntry.find_by!(slug: params[:guide_entry_id])
    end
end
