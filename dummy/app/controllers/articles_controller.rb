class ArticlesController < ApplicationController
  def show
    @article = Macron::Cms::Article.friendly.find(params[:id])
  end
end
