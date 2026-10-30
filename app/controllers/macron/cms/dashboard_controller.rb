module Macron
  module Cms
    class DashboardController < ApplicationController
      def index
        @articles_count = Article.count
        @recent_articles = Article.limit(5)
      end
    end
  end
end
