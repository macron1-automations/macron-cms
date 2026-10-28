module Widgets
  class HeadingComponent < Macron::Cms::WidgetComponent
    VALID_LEVELS = %w[h1 h2 h3 h4 h5 h6].freeze

    def tag_name
      raw_level = (level.presence || "h2").to_s.strip.downcase
      normalized = raw_level.start_with?("h") ? raw_level : "h#{raw_level}"
      VALID_LEVELS.include?(normalized) ? normalized : "h2"
    end

    def heading_classes
      case tag_name
      when "h1"
        "text-3xl sm:text-4xl font-extrabold tracking-tight text-zinc-900 mb-4"
      when "h2"
        "text-2xl sm:text-3xl font-bold tracking-tight text-zinc-900 mt-8 mb-3"
      when "h3"
        "text-xl sm:text-2xl font-semibold text-zinc-900 mt-6 mb-2"
      when "h4"
        "text-lg sm:text-xl font-semibold text-zinc-900 mt-4 mb-2"
      when "h5"
        "text-base sm:text-lg font-medium text-zinc-900 mt-3 mb-1"
      else
        "text-sm sm:text-base font-medium text-zinc-900 mt-2 mb-1"
      end
    end
  end
end
