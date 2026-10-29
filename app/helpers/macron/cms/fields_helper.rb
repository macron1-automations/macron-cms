require "kramdown"
require "kramdown-parser-gfm"

module Macron
  module Cms
    module FieldsHelper
      SUPPORTED_KINDS = %w[string text dropdown file color markdown json].freeze

      def cms_render_markdown(text)
        return "".html_safe if text.blank?

        raw_html = Kramdown::Document.new(text.to_s, input: "GFM").to_html
        sanitize(raw_html)
      end

      def cms_render_field(field_def, value: nil, input_name: nil, input_id: nil)
        field_hash = field_def.stringify_keys
        fname = field_hash["name"]
        fkind = field_hash["kind"].to_s.presence || "string"

        input_name ||= "article_content[payload][#{fname}]"
        input_id ||= "article_content_payload_#{fname}"

        partial_path = "macron/cms/fields/#{fkind}"
        unless lookup_context.exists?(partial_path, [], true)
          partial_path = "macron/cms/fields/string"
        end

        render partial: partial_path, locals: {
          field: field_hash,
          field_name: fname,
          field_kind: fkind,
          value: value,
          input_name: input_name,
          input_id: input_id
        }
      end
    end
  end
end
