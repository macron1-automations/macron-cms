namespace :macron do
  namespace :cms do
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
