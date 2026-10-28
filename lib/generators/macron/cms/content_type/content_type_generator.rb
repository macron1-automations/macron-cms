# frozen_string_literal: true

require "rails/generators/named_base"

module Macron
  module Cms
    module Generators
      class ContentTypeGenerator < ::Rails::Generators::NamedBase
        desc "Generates a Macron CMS content type YAML definition file and a matching ViewComponent widget in app/components/widgets/."

        argument :fields, type: :array, default: [], banner: "field:kind field:kind"

        def create_content_type_file
          parsed = parse_and_validate_fields
          target_path = File.join(base_directory.to_s, "#{file_name}.yml")
          create_file target_path, build_yaml(parsed)
        end

        def create_widget_component_files
          parsed = parse_and_validate_fields
          component_path = File.join("app/components/widgets", "#{file_name}_component.rb")
          template_path = File.join("app/components/widgets", "#{file_name}_component.html.erb")

          create_file component_path, build_widget_ruby
          create_file template_path, build_widget_template(parsed)
        end

        private

        def base_directory
          Macron::Cms.configuration.content_types_path || "config/content_types"
        end

        def parse_and_validate_fields
          @parsed_fields ||= fields.map do |field|
            parts = field.split(":", 2)
            if parts.length != 2 || parts[0].blank? || parts[1].blank?
              raise Thor::Error, "Invalid field '#{field}'. Fields must be in the format 'name:kind' (e.g. title:string)."
            end

            { "name" => parts[0], "kind" => parts[1] }
          end
        end

        def build_yaml(parsed_fields)
          if parsed_fields.empty?
            "fields: []\n"
          else
            lines = [ "fields:" ]
            parsed_fields.each do |f|
              lines << "  - name: '#{f['name']}'"
              lines << "    kind: '#{f['kind']}'"
            end
            "#{lines.join("\n")}\n"
          end
        end

        def build_widget_ruby
          <<~RUBY
            module Widgets
              class #{file_name.camelize}Component < Macron::Cms::WidgetComponent
              end
            end
          RUBY
        end

        def build_widget_template(parsed_fields)
          if parsed_fields.empty?
            <<~ERB
              <div class="my-4">
                <!-- #{file_name.camelize} Widget -->
              </div>
            ERB
          else
            field_tags = parsed_fields.map do |f|
              "  <p><%= #{f['name']} %></p>"
            end
            <<~ERB
              <div class="my-4">
              #{field_tags.join("\n")}
              </div>
            ERB
          end
        end
      end
    end
  end
end
