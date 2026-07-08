class PostsController < ApplicationController
  def index
    @posts = Post.published.recent.limit(50)
    @featured = @posts.detect(&:featured?)
  end

  def show
    @post = Post.published.find_by!(slug: params[:slug])
    @related = Post.published.recent.where.not(id: @post.id).limit(3)
  end
end
