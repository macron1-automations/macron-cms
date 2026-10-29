module Widgets
  class ThreeJsQuoteComponent < Macron::Cms::WidgetComponent
    DEFAULT_COLOR = "#18181b"
    VALID_ROTATION_AXES = %w[x y z].freeze
    DEFAULT_ROTATION_AXIS = "x"
    VALID_ROTATION_SPEEDS = %w[0 0.5 1 1.5 2 3].freeze
    DEFAULT_ROTATION_SPEED = "1"
    CANVAS_HEIGHT_CLASSES = {
      "sm" => "h-60",
      "md" => "h-64 sm:h-80",
      "lg" => "h-96 sm:h-[480px]",
      "xl" => "h-[540px] sm:h-[640px]"
    }.freeze
    DEFAULT_CANVAS_HEIGHT = "md"
    VALID_FONT_SIZES = %w[sm md lg xl].freeze
    DEFAULT_FONT_SIZE = "md"
    VALID_FONTS = %w[helvetiker optimer gentilis droid_serif].freeze
    DEFAULT_FONT = "helvetiker"
    DEFAULT_BACKGROUND_MODE = "stretch"
    VALID_SCANLINES_INTENSITIES = %w[off subtle medium strong].freeze
    DEFAULT_SCANLINES_INTENSITY = "off"
    VALID_SCANLINES_DENSITIES = %w[fine medium coarse].freeze
    DEFAULT_SCANLINES_DENSITY = "medium"
    VALID_SCANLINES_SPEEDS = %w[still slow normal fast].freeze
    DEFAULT_SCANLINES_SPEED = "normal"

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

    def rotation_speed
      spd = field_value("rotation_speed").presence
      normalized = spd.to_s.strip
      VALID_ROTATION_SPEEDS.include?(normalized) ? normalized : DEFAULT_ROTATION_SPEED
    end

    def canvas_height
      h = field_value("canvas_height").presence
      normalized = h.to_s.strip.downcase
      CANVAS_HEIGHT_CLASSES.key?(normalized) ? normalized : DEFAULT_CANVAS_HEIGHT
    end

    def canvas_height_class
      CANVAS_HEIGHT_CLASSES[canvas_height] || CANVAS_HEIGHT_CLASSES[DEFAULT_CANVAS_HEIGHT]
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

    def scanlines_intensity
      v = field_value("scanlines_intensity").presence
      normalized = v.to_s.strip.downcase
      VALID_SCANLINES_INTENSITIES.include?(normalized) ? normalized : DEFAULT_SCANLINES_INTENSITY
    end

    def scanlines_density
      v = field_value("scanlines_density").presence
      normalized = v.to_s.strip.downcase
      VALID_SCANLINES_DENSITIES.include?(normalized) ? normalized : DEFAULT_SCANLINES_DENSITY
    end

    def scanlines_speed
      v = field_value("scanlines_speed").presence
      normalized = v.to_s.strip.downcase
      VALID_SCANLINES_SPEEDS.include?(normalized) ? normalized : DEFAULT_SCANLINES_SPEED
    end
  end
end
