module Macron
  module Cms
    class Engine < ::Rails::Engine
      isolate_namespace Macron::Cms

      initializer :append_migrations do |app|
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end

      initializer "macron_cms.helpers" do
        ActiveSupport.on_load(:action_view) do
          include Macron::Cms::SeoHelper
          include Macron::Cms::ContentHelper
        end
      end
    end
  end
end
