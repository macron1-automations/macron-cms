module Macron
  module Cms
    module Api
      module V1
        class ContentTypesController < BaseController
          def index
            content_types = Content.order(:name).map do |ct|
              {
                id: ct.id,
                name: ct.name,
                fields: ct.normalized_fields,
                convertible_to: ct.normalized_convertible_to
              }
            end

            render json: { content_types: content_types }
          end
        end
      end
    end
  end
end
