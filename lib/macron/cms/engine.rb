module Macron
  module Cms
    class Engine < ::Rails::Engine
      isolate_namespace Macron::Cms

      initializer :append_migrations do |app|
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
