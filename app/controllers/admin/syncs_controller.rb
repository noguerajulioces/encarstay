class Admin::SyncsController < Admin::BaseController
  def create
    @property = Property.find_by!(slug: params[:property_id])
    source = @property.calendar_sources.find(params[:calendar_source_id])
    ImportCalendarJob.perform_later(source)
    redirect_to admin_property_path(@property), notice: "Sincronizando #{source.name}…"
  end
end
