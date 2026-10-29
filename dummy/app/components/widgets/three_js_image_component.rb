module Widgets
  class ThreeJsImageComponent < Macron::Cms::WidgetComponent
    SIZE_CLASSES = {
      "sm"   => "w-full sm:w-1/3 mx-auto",
      "md"   => "w-full sm:w-1/2 mx-auto",
      "lg"   => "w-full sm:w-3/4 mx-auto",
      "full" => "w-full"
    }.freeze
    DEFAULT_SIZE = "md"

    CANVAS_HEIGHT_CLASSES = {
      "sm" => "h-60",
      "md" => "h-64 sm:h-80",
      "lg" => "h-96 sm:h-[480px]",
      "xl" => "h-[540px] sm:h-[640px]"
    }.freeze
    DEFAULT_CANVAS_HEIGHT = "md"

    VALID_EFFECTS = %w[ripple wave glitch].freeze
    DEFAULT_EFFECT = "ripple"

    VALID_ANIMATION_SPEEDS = %w[slow normal fast].freeze
    DEFAULT_ANIMATION_SPEED = "normal"

    VALID_INTENSITIES = %w[subtle medium strong].freeze
    DEFAULT_INTENSITY = "medium"

    VALID_FIT_MODES = %w[cover contain].freeze
    DEFAULT_FIT_MODE = "cover"

    def render?
      image_source.present?
    end

    def image_source
      return nil unless upload.present?

      if upload.respond_to?(:blob)
        helpers.url_for(upload)
      elsif upload.respond_to?(:attached?) && upload.attached?
        helpers.url_for(upload)
      elsif upload.is_a?(String) && upload.present?
        upload
      else
        upload.to_s.presence
      end
    rescue StandardError
      upload.to_s.presence
    end

    def size
      s = field_value("size").presence
      SIZE_CLASSES.key?(s) ? s : DEFAULT_SIZE
    end

    def container_classes
      SIZE_CLASSES[size] || SIZE_CLASSES[DEFAULT_SIZE]
    end

    def canvas_height
      h = field_value("canvas_height").presence
      normalized = h.to_s.strip.downcase
      CANVAS_HEIGHT_CLASSES.key?(normalized) ? normalized : DEFAULT_CANVAS_HEIGHT
    end

    def canvas_height_class
      CANVAS_HEIGHT_CLASSES[canvas_height] || CANVAS_HEIGHT_CLASSES[DEFAULT_CANVAS_HEIGHT]
    end

    def effect
      eff = field_value("effect").presence
      normalized = eff.to_s.strip.downcase
      VALID_EFFECTS.include?(normalized) ? normalized : DEFAULT_EFFECT
    end

    def animation_speed
      spd = field_value("animation_speed").presence
      normalized = spd.to_s.strip.downcase
      VALID_ANIMATION_SPEEDS.include?(normalized) ? normalized : DEFAULT_ANIMATION_SPEED
    end

    def intensity
      inten = field_value("intensity").presence
      normalized = inten.to_s.strip.downcase
      VALID_INTENSITIES.include?(normalized) ? normalized : DEFAULT_INTENSITY
    end

    def fit_mode
      fm = field_value("fit_mode").presence
      normalized = fm.to_s.strip.downcase
      VALID_FIT_MODES.include?(normalized) ? normalized : DEFAULT_FIT_MODE
    end
  end
end
