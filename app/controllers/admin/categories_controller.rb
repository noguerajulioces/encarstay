class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: %i[ edit update destroy ]

  def index
    @categories = Category.ordered
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to admin_categories_path, notice: "Categoría creada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: "Cambios guardados."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    redirect_to admin_categories_path, notice: "Categoría eliminada."
  end

  private
    def set_category
      @category = Category.find_by!(slug: params[:id])
    end

    def category_params
      params.require(:category).permit(:name_es, :name_en, :name_pt, :icon, :position)
    end
end
