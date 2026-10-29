module Widgets
  class ImageComponent < Macron::Cms::WidgetComponent
    def render?
      upload.present?
    end

    def image_source
      return nil unless upload.present?

      if upload.respond_to?(:blob)
        upload
      else
        upload.to_s
      end
    end
  end
end
