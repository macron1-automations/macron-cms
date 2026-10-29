module Widgets
  class EmbedComponent < Macron::Cms::WidgetComponent
    include Rails.application.routes.url_helpers

    def render?
      upload.present?
    end

    def embed_url
      return nil unless upload.present?

      if upload.respond_to?(:blob)
        rails_blob_path(upload, disposition: :inline)
      else
        upload.to_s
      end
    end
  end
end
