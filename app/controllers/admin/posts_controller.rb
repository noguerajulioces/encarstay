class Admin::PostsController < Admin::BaseController
  before_action :set_post, only: %i[ edit update destroy ]

  def index
    @posts = Post.ordered
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)
    if @post.save
      attach_cover
      redirect_to edit_admin_post_path(@post), notice: "Artículo creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      attach_cover
      redirect_to edit_admin_post_path(@post), notice: "Cambios guardados."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to admin_posts_path, notice: "Artículo eliminado."
  end

  private
    def set_post
      @post = Post.find_by!(slug: params[:id])
    end

    def attach_cover
      @post.cover_image.attach(params[:cover_image]) if params[:cover_image].present?
    end

    def post_params
      params.require(:post).permit(
        :category_id,
        :title_es, :title_en, :title_pt,
        :excerpt_es, :excerpt_en, :excerpt_pt,
        :meta_description_es, :meta_description_en, :meta_description_pt,
        :body_es, :body_en, :body_pt,
        :featured, :published, :published_at, :position
      )
    end
end
