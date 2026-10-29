module Macron
  module Cms
    module ContentHelper
      def cms_render_article_contents(article)
        return "".html_safe if article.nil?

        contents = article.article_contents.includes(:content).order(:sort_order, :id)
        rendered = contents.map { |ac| cms_render_widget(ac) }
        safe_join(rendered)
      end

      def cms_render_widget(article_content)
        return "".html_safe if article_content.nil? || article_content.content.nil?

        content_name = article_content.content.name.to_s
        widget_class_name = "Widgets::#{content_name.camelize}Component"
        widget_class = widget_class_name.safe_constantize

        unless widget_class
          raise Macron::Cms::MissingWidgetError,
                "Missing widget component #{widget_class_name} for content type '#{content_name}'."
        end

        render widget_class.new(
          article_content: article_content,
          payload: article_content.payload,
          fields: article_content.content.normalized_fields
        )
      end

      def cms_article_background_style(article)
        return "" if article.nil?

        styles = []
        if article.background_color.present?
          styles << "background-color: #{article.background_color};"
        end

        if article.respond_to?(:background_image) && article.background_image.attached?
          image_path = if respond_to?(:rails_blob_path)
                         rails_blob_path(article.background_image, only_path: true)
          elsif respond_to?(:url_for)
                         url_for(article.background_image)
          else
                         Rails.application.routes.url_helpers.rails_blob_path(article.background_image, only_path: true)
          end
          styles << "background-image: url('#{image_path}');"
          styles << "background-repeat: #{article.background_repeat};"
          styles << "background-size: #{article.background_size};"
          styles << "background-position: #{article.background_position};"
          styles << "background-attachment: #{article.background_attachment};"
        end

        styles.join(" ")
      end
    end
  end
end
