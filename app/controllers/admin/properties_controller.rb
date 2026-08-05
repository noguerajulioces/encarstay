class Admin::PropertiesController < Admin::BaseController
  before_action :set_property, only: %i[ show edit update destroy ]

  def index
    @properties = Property.alphabetically
  end

  def show
  end

  def new
    @property = Property.new
  end

  def create
    @property = Property.new(property_params)
    if @property.save
      attach_photos
      redirect_to admin_property_path(@property), notice: "Propiedad creada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @property.update(property_params)
      attach_photos
      redirect_to admin_property_path(@property), notice: "Cambios guardados."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @property.destroy
    redirect_to admin_properties_path, notice: "Propiedad eliminada."
  end

  private
    def set_property
      @property = Property.find_by!(slug: params[:id])
    end

    def attach_photos
      Array(params[:photos]).reject(&:blank?).each do |file|
        @property.photos.create!(image: file, position: @property.photos.count)
      end
    end

    def property_params
      params.require(:property).permit(:name, :property_type, :description, :address_area, :latitude, :longitude,
        :capacity, :bedrooms, :beds, :bathrooms, :base_price_cents, :currency, :cleaning_fee_cents,
        :min_nights, :active, :airbnb_listing_url, :airbnb_public_url, amenity_ids: [])
    end
end
