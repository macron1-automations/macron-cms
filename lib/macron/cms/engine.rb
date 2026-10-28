module Macron
  module Cms
    class Engine < ::Rails::Engine
      isolate_namespace Macron::Cms
    end
  end
end
