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
      return unless article_text_color.present?

      color = article_text_color
      [
        "color: #{color};",
        "--tw-prose-body: #{color};",
        "--tw-prose-headings: #{color};",
        "--tw-prose-lead: #{color};",
        "--tw-prose-links: #{color};",
        "--tw-prose-bold: #{color};",
        "--tw-prose-counters: #{color};",
        "--tw-prose-bullets: #{color};",
        "--tw-prose-hr: #{color};",
        "--tw-prose-quotes: #{color};",
        "--tw-prose-quote-borders: #{color};",
        "--tw-prose-captions: #{color};",
        "--tw-prose-code: #{color};",
        "--tw-prose-th-borders: #{color};",
        "--tw-prose-td-borders: #{color};"
      ].join(" ")
    end

    def markdown_classes
      base = "prose max-w-none my-4"
      article_text_color.present? ? base : "#{base} prose-zinc"
    end
  end
end
