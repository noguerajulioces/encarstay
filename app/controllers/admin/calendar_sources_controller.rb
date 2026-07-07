class Admin::CalendarSourcesController < Admin::BaseController
  before_action :set_property

  def create
    if @property.calendar_sources.create(calendar_source_params).persisted?
      redirect_to admin_property_path(@property), notice: "Calendario agregado. Sincronizá para importar."
    else
      redirect_to admin_property_path(@property), alert: "Necesitás una URL iCal válida."
    end
  end

  def update
    @property.calendar_sources.find(params[:id]).update(calendar_source_params)
    redirect_to admin_property_path(@property), notice: "Calendario actualizado."
  end

  def destroy
    @property.calendar_sources.find(params[:id]).destroy
    redirect_to admin_property_path(@property), notice: "Calendario eliminado."
  end

  private
    def set_property
      @property = Property.find_by!(slug: params[:property_id])
    end

    def calendar_source_params
      params.permit(:name, :ical_url, :active)
    end
end
