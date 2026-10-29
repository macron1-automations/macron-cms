module Macron
  module Cms
    class WidgetComponent < ViewComponent::Base
      attr_reader :payload, :fields, :article_content

      def initialize(payload: {}, fields: [], article_content: nil)
        @payload = (payload || {}).to_h.stringify_keys
        @fields = Array(fields).map { |f| f.respond_to?(:stringify_keys) ? f.stringify_keys : f }
        @article_content = article_content

        # Define dynamic reader methods on the singleton class of this instance
        # ensuring fields like `content` override ViewComponent::Base#content (slot block content)
        singleton = class << self; self; end
        reserved_keys = %w[upload file uploads files]
        field_keys = (@payload.keys + defined_field_names).uniq
        field_keys.each do |key|
          next if key.blank? || reserved_keys.include?(key)
          singleton.define_method(key) { @payload[key] }
        end
      end

      def upload
        @article_content&.upload.presence || @payload["upload"]
      end

      def file
        @article_content&.file.presence || @payload["file"]
      end

      def uploads
        @article_content&.uploads
      end

      def files
        @article_content&.files
      end

      def field_value(name)
        @payload[name.to_s]
      end

      def article_text_color
        @article_content&.article&.text_color.presence
      end

      def defined_field_names
        @fields.filter_map { |f| f["name"] if f.is_a?(Hash) }
      end
    end
  end
end
