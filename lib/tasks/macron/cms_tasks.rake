namespace :macron do
  namespace :cms do
    desc "Import content types from YAML files into Macron::Cms::Content"
    task import_content_types: :environment do
      require "yaml"

      base_path = Macron::Cms.configuration.content_types_path ||
                  (defined?(Rails.root) && Rails.root ? Rails.root.join("config", "content_types") : File.expand_path("config/content_types"))
      directory = Pathname.new(base_path)

      unless directory.exist?
        puts "Content types directory '#{directory}' does not exist. Skipping import."
        next
      end

      files = Dir.glob(directory.join("*.{yml,yaml}")).sort

      if files.empty?
        puts "No YAML content types found in #{directory}."
        next
      end

      files.each do |file|
        content_type_name = File.basename(file, ".*")
        data = YAML.safe_load_file(file, permitted_classes: [ Symbol ], aliases: true) || {}
        fields = data["fields"] || data[:fields] || {}

        content = Macron::Cms::Content.find_or_initialize_by(name: content_type_name)
        content.fields = fields
        content.save!

        puts "Imported content type: #{content_type_name}"
      end
    end

    namespace :content do
      desc "Alias for macron:cms:import_content_types"
      task import: :"macron:cms:import_content_types"
    end

    namespace :tailwind do
      def tailwind_executable
        require "tailwindcss/ruby"
        Tailwindcss::Ruby.executable
      rescue LoadError
        "tailwindcss"
      end

      desc "Build Macron CMS Tailwind CSS"
      task :build do
        engine_root = File.expand_path("../../..", __dir__)
        input = File.join(engine_root, "app/assets/tailwind/macron/cms/application.css")
        output = File.join(engine_root, "app/assets/stylesheets/macron/cms/application.css")

        exe = tailwind_executable
        cmd = [ exe, "-i", input, "-o", output, "--minify" ]
        puts "Building Macron CMS Tailwind CSS..."
        success = system(*cmd, chdir: engine_root)
        abort("Tailwind build failed") unless success
      end

      desc "Watch Macron CMS Tailwind CSS for changes"
      task :watch do
        engine_root = File.expand_path("../../..", __dir__)
        input = File.join(engine_root, "app/assets/tailwind/macron/cms/application.css")
        output = File.join(engine_root, "app/assets/stylesheets/macron/cms/application.css")

        exe = tailwind_executable
        cmd = [ exe, "-i", input, "-o", output, "-w" ]
        puts "Watching Macron CMS Tailwind CSS..."
        system(*cmd, chdir: engine_root)
      end
    end
  end
end
