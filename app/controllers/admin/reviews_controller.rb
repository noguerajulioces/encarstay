class Admin::ReviewsController < Admin::BaseController
  before_action :set_property
  before_action :set_review, only: %i[ edit update destroy ]

  def index
    @reviews = @property.reviews.recent
  end

  def new
    @review = @property.reviews.new(rating: 5, stayed_on: Date.current)
  end

  def create
    # Reviews the admin types in by hand are public straight away; only guest
    # submissions wait for approval.
    @review = @property.reviews.new(review_params.merge(approved_at: Time.current))
    if @review.save
      redirect_to admin_property_reviews_path(@property), notice: "Reseña agregada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_to admin_property_reviews_path(@property), notice: "Cambios guardados."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to admin_property_reviews_path(@property), notice: "Reseña eliminada."
  end

  private
    def set_property
      @property = Property.find_by!(slug: params[:property_id])
    end

    def set_review
      @review = @property.reviews.find(params[:id])
    end

    def review_params
      params.require(:review).permit(:reviewer_name, :reviewer_location, :rating, :body, :stayed_on)
    end
end
