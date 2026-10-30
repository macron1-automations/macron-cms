require "open-uri"
require "net/http"

module Macron
  module Cms
    class RemoteAssetAttacher
      MAX_FILE_SIZE = 25.megabytes
      READ_TIMEOUT = 10
      OPEN_TIMEOUT = 5

      def self.attach(article_content:, url:, replace: true)
        new(record: article_content, association: :files, url: url, replace: replace).call
      end

      def self.attach_background(article:, url:, replace: true)
        new(record: article, association: :background_image, url: url, replace: replace).call
      end

      def initialize(record: nil, association: :files, article_content: nil, url:, replace: true)
        @record = record || article_content
        @association = association
        @article_content = article_content || (@record.is_a?(ArticleContent) ? @record : nil)
        @url = url.to_s.strip
        @replace = replace
      end

      def call
        return false if @url.blank?

        uri = URI.parse(@url)
        return false unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

        download_and_attach(uri)
      rescue => e
        Rails.logger.warn("[Macron::Cms::RemoteAssetAttacher] Failed to download remote asset from #{@url}: #{e.message}")
        fallback_to_payload_url
        false
      end

      private

      def download_and_attach(uri)
        options = {
          read_timeout: READ_TIMEOUT,
          open_timeout: OPEN_TIMEOUT,
          "User-Agent" => "MacronCMS/1.0"
        }

        downloaded_io = URI.open(uri, options) # rubocop:disable Security/Open

        if downloaded_io.size > MAX_FILE_SIZE
          Rails.logger.warn("[Macron::Cms::RemoteAssetAttacher] File from #{@url} exceeds #{MAX_FILE_SIZE} bytes")
          fallback_to_payload_url
          return false
        end

        filename = derive_filename(uri, downloaded_io)
        content_type = downloaded_io.content_type || "application/octet-stream"

        target_assoc = @record.public_send(@association)

        if @replace && target_assoc.respond_to?(:attached?) && target_assoc.attached?
          target_assoc.purge
        end

        downloaded_io.rewind if downloaded_io.respond_to?(:rewind)

        target_assoc.attach(
          io: downloaded_io,
          filename: filename,
          content_type: content_type
        )

        true
      end

      def derive_filename(uri, io)
        basename = File.basename(uri.path.to_s)
        if basename.present? && basename.include?(".")
          basename
        else
          ext = Rack::Mime::MIME_TYPES.invert[io.content_type] || ".bin"
          "asset_#{SecureRandom.hex(6)}#{ext}"
        end
      end

      def fallback_to_payload_url
        return unless @article_content

        current_payload = (@article_content.payload || {}).dup
        current_payload["upload"] = @url
        @article_content.payload = current_payload
      end
    end
  end
end
