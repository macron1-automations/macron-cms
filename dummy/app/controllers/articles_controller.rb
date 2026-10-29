class ArticlesController < ApplicationController
  include Macron::Cms::SlugRedirectable

  def index
    redirect_to root_path, status: :moved_permanently
  end

  def show
    @article = Macron::Cms::Article.friendly.find(params[:id])
    redirect_to_canonical_slug_if_needed(@article)
  end
end
