class PagesController < ApplicationController
  include Pagy::Method

  ARTICLES_PER_PAGE = 5

  def index
    scope = Macron::Cms::Article.includes(:featured_image_blob).order(created_at: :desc)
    @pagy, @articles = pagy(:offset, scope, limit: ARTICLES_PER_PAGE)
  end
end
