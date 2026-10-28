class PagesController < ApplicationController
  def index
    @articles = Macron::Cms::Article.order(created_at: :desc)
  end
end
