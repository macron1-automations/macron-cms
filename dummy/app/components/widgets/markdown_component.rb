require "kramdown"
require "kramdown-parser-gfm"

module Widgets
  class MarkdownComponent < Macron::Cms::WidgetComponent
    def rendered_html
      return "".html_safe if content.blank?

      raw_html = Kramdown::Document.new(content.to_s, input: "GFM").to_html
      helpers.sanitize(raw_html)
    end

    def custom_style
      "color: #{article_text_color};" if article_text_color.present?
    end

    def markdown_classes
      base = "prose prose-zinc max-w-none my-4"
      article_text_color.present? ? "#{base} prose-inherit" : base
    end
  end
end
