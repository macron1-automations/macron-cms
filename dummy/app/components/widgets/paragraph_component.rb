module Widgets
  class ParagraphComponent < Macron::Cms::WidgetComponent
    def custom_style
      "color: #{article_text_color};" if article_text_color.present?
    end

    def paragraph_classes
      base = "text-base leading-relaxed my-4 whitespace-pre-wrap"
      article_text_color.present? ? base : "#{base} text-zinc-700"
    end
  end
end
