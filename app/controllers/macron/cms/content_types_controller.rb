module Macron
  module Cms
    class ContentTypesController < ApplicationController
      before_action :set_content_type, only: %i[show]

      def index
        @content_types = Content.order(:name)
      end

      def show
      end

      private

      def set_content_type
        @content_type = Content.find(params[:id])
      end
    end
  end
end
