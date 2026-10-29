module Widgets
  class HeadingComponent < Macron::Cms::WidgetComponent
    VALID_LEVELS = %w[h1 h2 h3 h4 h5 h6].freeze

    def tag_name
      raw_level = (level.presence || "h2").to_s.strip.downcase
      normalized = raw_level.start_with?("h") ? raw_level : "h#{raw_level}"
      VALID_LEVELS.include?(normalized) ? normalized : "h2"
    end

    def custom_color
      c = (respond_to?(:color) ? color : nil).presence || field_value("color").presence
      c.to_s.strip.presence
    end

    def custom_style
      "color: #{custom_color};" if custom_color.present?
    end

    def heading_classes
      base = case tag_name
      when "h1"
        "text-3xl sm:text-4xl font-extrabold tracking-tight mb-4"
      when "h2"
        "text-2xl sm:text-3xl font-bold tracking-tight mt-8 mb-3"
      when "h3"
        "text-xl sm:text-2xl font-semibold mt-6 mb-2"
      when "h4"
        "text-lg sm:text-xl font-semibold mt-4 mb-2"
      when "h5"
        "text-base sm:text-lg font-medium mt-3 mb-1"
      else
        "text-sm sm:text-base font-medium mt-2 mb-1"
      end

      custom_color.present? ? base : "#{base} text-zinc-900"
    end
  end
end
