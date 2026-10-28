module Macron
  module Cms
    class WidgetComponent < ViewComponent::Base
      attr_reader :payload, :fields

      def initialize(payload: {}, fields: [])
        @payload = (payload || {}).to_h.stringify_keys
        @fields = Array(fields).map { |f| f.respond_to?(:stringify_keys) ? f.stringify_keys : f }

        # Define dynamic reader methods on the singleton class of this instance
        # ensuring fields like `content` override ViewComponent::Base#content (slot block content)
        singleton = class << self; self; end
        field_keys = (@payload.keys + defined_field_names).uniq
        field_keys.each do |key|
          next if key.blank?
          singleton.define_method(key) { @payload[key] }
        end
      end

      def field_value(name)
        @payload[name.to_s]
      end

      def defined_field_names
        @fields.filter_map { |f| f["name"] if f.is_a?(Hash) }
      end
    end
  end
end
