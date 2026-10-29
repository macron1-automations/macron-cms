module Widgets
  class ImageComponent < Macron::Cms::WidgetComponent
    SIZE_CLASSES = {
      "sm"   => "w-full sm:w-1/3 mx-auto",
      "md"   => "w-full sm:w-1/2 mx-auto",
      "lg"   => "w-full sm:w-3/4 mx-auto",
      "full" => "w-full"
    }.freeze

    def render?
      upload.present?
    end

    def size
      field_value(:size)
    end

    def container_classes
      SIZE_CLASSES[size.presence || "md"] || SIZE_CLASSES["md"]
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
