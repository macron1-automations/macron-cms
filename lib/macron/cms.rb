require "friendly_id"
require "devise"
require "view_component"
require "macron/cms/version"
require "macron/cms/configuration"
require "macron/cms/engine"

module Macron
  module Cms
    class MissingWidgetError < StandardError; end

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      def reset_configuration!
        @configuration = Configuration.new
      end
    end
  end
end
