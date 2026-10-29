module Widgets
  class ThreeJsQuoteComponent < Macron::Cms::WidgetComponent
    DEFAULT_COLOR = "#18181b"
    VALID_ROTATION_AXES = %w[x y z].freeze
    DEFAULT_ROTATION_AXIS = "x"
    VALID_FONT_SIZES = %w[sm md lg xl].freeze
    DEFAULT_FONT_SIZE = "md"
    VALID_FONTS = %w[helvetiker optimer gentilis droid_serif].freeze
    DEFAULT_FONT = "helvetiker"
    DEFAULT_BACKGROUND_MODE = "stretch"

    def render?
      quote_text.present?
    end

    def quote_text
      raw = field_value("text").presence
      raw.to_s.strip.presence
    end

    def custom_color
      c = field_value("color").presence
      c.to_s.strip.presence
    end

    def effective_color
      custom_color.presence || article_text_color.presence || DEFAULT_COLOR
    end

    def rotation_axis
      axis = field_value("rotation_axis").presence
      normalized = axis.to_s.strip.downcase
      VALID_ROTATION_AXES.include?(normalized) ? normalized : DEFAULT_ROTATION_AXIS
    end

    def font_size
      size = field_value("font_size").presence
      normalized = size.to_s.strip.downcase
      VALID_FONT_SIZES.include?(normalized) ? normalized : DEFAULT_FONT_SIZE
    end

    def font
      f = field_value("font").presence
      normalized = f.to_s.strip.downcase
      VALID_FONTS.include?(normalized) ? normalized : DEFAULT_FONT
    end

    def background_color
      field_value("background_color").to_s.strip.presence
    end

    def background_image_url
      return nil unless upload.present?

      if upload.respond_to?(:blob)
        helpers.url_for(upload)
      elsif upload.respond_to?(:attached?) && upload.attached?
        helpers.url_for(upload)
      elsif upload.is_a?(String) && upload.present?
        upload
      end
    rescue StandardError
      upload.to_s.presence
    end

    def background_mode
      mode = field_value("background_mode").presence
      normalized = mode.to_s.strip.downcase
      normalized == "tile" ? "tile" : DEFAULT_BACKGROUND_MODE
    end
  end
end
