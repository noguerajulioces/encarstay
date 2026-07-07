class Admin::BlocksController < Admin::BaseController
  def create
    property = Property.find(params[:property_id])
    if property.blocks.create(block_params).persisted?
      redirect_back_or_to admin_calendar_path, notice: "Fechas bloqueadas."
    else
      redirect_back_or_to admin_calendar_path, alert: "Revisá las fechas del bloqueo."
    end
  end

  def destroy
    Block.find(params[:id]).destroy
    redirect_back_or_to admin_calendar_path, notice: "Bloqueo eliminado."
  end

  private
    def block_params
      params.permit(:starts_on, :ends_on, :reason)
    end
end
