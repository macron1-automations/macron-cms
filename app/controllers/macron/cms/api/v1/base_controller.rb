module Macron
  module Cms
    module Api
      module V1
        class BaseController < ActionController::API
          before_action :authenticate_api_key!

          private

          def authenticate_api_key!
            expected_key = Macron::Cms.configuration.api_key.presence

            # In development and test, if no API key is configured, allow requests to facilitate local setup.
            return if expected_key.blank? && (Rails.env.development? || Rails.env.test?)

            token = extracted_token

            if expected_key.blank? || token.blank? || !ActiveSupport::SecurityUtils.secure_compare(token, expected_key)
              render json: { error: "Unauthorized. Missing or invalid API key." }, status: :unauthorized
            end
          end

          def extracted_token
            auth_header = request.headers["Authorization"].to_s
            if auth_header.downcase.start_with?("bearer ")
              auth_header.split(" ", 2).last.to_s.strip
            else
              request.headers["X-API-Key"].to_s.strip
            end
          end
        end
      end
    end
  end
end
