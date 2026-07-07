class Admin::PhotosController < Admin::BaseController
  def destroy
    property = Property.find_by!(slug: params[:property_id])
    property.photos.find(params[:id]).destroy
    redirect_to admin_property_path(property), notice: "Foto eliminada."
  end
end
