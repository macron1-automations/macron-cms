module Macron
  module Cms
    class DashboardController < ApplicationController
      def index
        @articles_count = Article.count
        @recent_articles = Article.order(created_at: :desc).limit(5)
      end
    end
  end
end
