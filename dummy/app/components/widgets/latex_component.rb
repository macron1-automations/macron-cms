module Widgets
  class LatexComponent < Macron::Cms::WidgetComponent
    def formula
      content.to_s
    end

    def custom_style
      return unless article_text_color.present?

      "color: #{article_text_color};"
    end

    def latex_classes
      "cms-latex-widget my-6 overflow-x-auto py-2 text-center"
    end
  end
end
