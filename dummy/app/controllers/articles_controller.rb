class ArticlesController < ApplicationController
  def index
    redirect_to root_path, status: :moved_permanently
  end

  def show
    @article = Macron::Cms::Article.friendly.find(params[:id])
  end
end
