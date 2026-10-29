module Widgets
  class EmbedComponent < Macron::Cms::WidgetComponent
    def render?
      upload.present?
    end

    def embed_html
      return nil unless upload.present?

      raw = if upload.respond_to?(:download)
        upload.download
      elsif upload.respond_to?(:read)
        upload.read
      else
        upload.to_s
      end

      raw.to_s.force_encoding("UTF-8")
    rescue StandardError => e
      Rails.logger.error("Failed to load embed attachment: #{e.message}")
      nil
    end
  end
end
