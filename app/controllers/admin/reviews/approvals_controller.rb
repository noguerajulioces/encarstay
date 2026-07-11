class Admin::Reviews::ApprovalsController < Admin::BaseController
  def create
    property = Property.find_by!(slug: params[:property_id])
    property.reviews.find(params[:review_id]).approve!
    redirect_to admin_property_reviews_path(property), notice: "Reseña aprobada y publicada."
  end
end
