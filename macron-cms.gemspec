require_relative "lib/macron/cms/version"

Gem::Specification.new do |spec|
  spec.name        = "macron-cms"
  spec.version     = Macron::Cms::VERSION
  spec.authors     = [ "Leonid Medovyy" ]
  spec.email       = [ "leonid@macron1.io" ]
  spec.homepage    = "https://github.com/macron1-automations/macron-cms"
  spec.summary     = "Simple CMS for building highly interactive content."
  spec.description = "A flexible Rails CMS engine designed for building highly interactive content with a wp_loop-inspired data architecture, Hotwire and React/Three.js hydration, and an AI-friendly migration API."
  spec.license     = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/macron1-automations/macron-cms"
  spec.metadata["changelog_uri"] = "https://github.com/macron1-automations/macron-cms/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.3.1"
  spec.add_dependency "friendly_id", "~> 5.5"
  spec.add_dependency "devise", ">= 4.9"
end
