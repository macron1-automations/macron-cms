module Widgets
  class ThreeJsQuoteComponent < Macron::Cms::WidgetComponent
    DEFAULT_COLOR = "#18181b"

    def render?
      quote_text.present?
    end

    def quote_text
      raw = (respond_to?(:text) ? text : nil).presence || field_value("text").presence
      raw.to_s.strip.presence
    end

    def custom_color
      c = (respond_to?(:color) ? color : nil).presence || field_value("color").presence
      c.to_s.strip.presence
    end

    def effective_color
      custom_color.presence || article_text_color.presence || DEFAULT_COLOR
    end
  end
end
