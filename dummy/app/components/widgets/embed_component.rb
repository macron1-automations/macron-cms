module Widgets
  class EmbedComponent < Macron::Cms::WidgetComponent
    SIZE_CLASSES = {
      "sm"   => "w-full sm:w-1/3 mx-auto",
      "md"   => "w-full sm:w-1/2 mx-auto",
      "lg"   => "w-full sm:w-3/4 mx-auto",
      "full" => "w-full"
    }.freeze

    HEIGHT_CLASSES = {
      "lg"  => "h-96 sm:h-[480px]",
      "xl"  => "h-[540px] sm:h-[640px]",
      "2xl" => "h-[640px] sm:h-[800px]"
    }.freeze
    DEFAULT_HEIGHT = "lg"

    def render?
      upload.present?
    end

    def size
      field_value(:size)
    end

    def container_classes
      SIZE_CLASSES[size.presence || "md"] || SIZE_CLASSES["md"]
    end

    def height
      h = field_value(:height).presence
      normalized = h.to_s.strip.downcase
      HEIGHT_CLASSES.key?(normalized) ? normalized : DEFAULT_HEIGHT
    end

    def height_class
      HEIGHT_CLASSES[height] || HEIGHT_CLASSES[DEFAULT_HEIGHT]
    end

    def embed_html
      return nil unless upload.present?

      raw = if upload.respond_to?(:download)
        upload.download
      elsif upload.respond_to?(:read)
        upload.read
      else
        upload.to_s
      end

      raw.to_s.force_encoding("UTF-8")
    rescue StandardError => e
      Rails.logger.error("Failed to load embed attachment: #{e.message}")
      nil
    end
  end
end
