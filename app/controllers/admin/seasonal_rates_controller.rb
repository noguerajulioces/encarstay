class Admin::SeasonalRatesController < Admin::BaseController
  before_action :set_property

  def create
    if @property.seasonal_rates.create(seasonal_rate_params).persisted?
      redirect_to admin_property_path(@property), notice: "Tarifa agregada."
    else
      redirect_to admin_property_path(@property), alert: "Revisá las fechas y el precio de la tarifa."
    end
  end

  def destroy
    @property.seasonal_rates.find(params[:id]).destroy
    redirect_to admin_property_path(@property), notice: "Tarifa eliminada."
  end

  private
    def set_property
      @property = Property.find_by!(slug: params[:property_id])
    end

    def seasonal_rate_params
      params.permit(:name, :starts_on, :ends_on, :price_per_night, :min_nights)
    end
end
