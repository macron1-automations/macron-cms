# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"

module Widgets
  class BlockquoteComponent < Macron::Cms::WidgetComponent
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
        "border-color: #{color};",
        "--tw-prose-body: #{color};",
        "--tw-prose-headings: #{color};",
        "--tw-prose-lead: #{color};",
        "--tw-prose-links: #{color};",
        "--tw-prose-bold: #{color};",
        "--tw-prose-quotes: #{color};",
        "--tw-prose-quote-borders: #{color};",
        "--tw-prose-code: #{color};"
      ].join(" ")
    end

    def blockquote_classes
      base = "border-l-4 pl-4 py-1.5 italic my-6 max-w-none text-zinc-700 dark:text-zinc-300"
      if article_text_color.present?
        base
      else
        "#{base} border-zinc-300 dark:border-zinc-700"
      end
    end
  end
end
