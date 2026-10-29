module Macron
  module Cms
    class ContentTypesController < ApplicationController
      before_action :set_content_type, only: %i[show]

      def index
        @content_types = Content.order(:name)
        @content_types_by_name = @content_types.index_by(&:name)
      end

      def show
        @convertible_targets_by_name = Content.where(name: @content_type.normalized_convertible_to).index_by(&:name)
      end

      private

      def set_content_type
        @content_type = Content.find(params[:id])
      end
    end
  end
end
