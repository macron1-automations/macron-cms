require "base64"
require "stringio"
require "securerandom"

module Macron
  module Cms
    class InlineAssetAttacher
      MAX_FILE_SIZE = 25.megabytes

      def self.attach(article_content:, upload_data:, replace: true)
        new(record: article_content, association: :files, upload_data: upload_data, replace: replace).call
      end

      def self.attach_background(article:, upload_data:, replace: true)
        new(record: article, association: :background_image, upload_data: upload_data, replace: replace).call
      end

      def initialize(record:, association:, upload_data:, replace: true)
        @record = record
        @association = association
        @upload_data = upload_data.respond_to?(:to_unsafe_h) ? upload_data.to_unsafe_h : upload_data.to_h
        @replace = replace
      end

      def call
        return false if @upload_data.blank?

        data_str = (@upload_data["data_base64"] || @upload_data[:data_base64] || @upload_data["data"] || @upload_data[:data]).to_s.strip
        return false if data_str.blank?

        # Strip optional data URI scheme prefix: data:image/png;base64,...
        raw_base64 = data_str.sub(/\Adata:[^;]+;base64,/, "")
        binary_data = Base64.decode64(raw_base64)

        if binary_data.bytesize > MAX_FILE_SIZE
          raise ArgumentError, "Uploaded file exceeds maximum size of #{MAX_FILE_SIZE} bytes"
        end

        filename = (@upload_data["filename"] || @upload_data[:filename]).to_s.strip
        content_type = (@upload_data["content_type"] || @upload_data[:content_type]).to_s.strip

        if filename.blank?
          ext = Rack::Mime::MIME_TYPES.invert[content_type] || ".bin"
          filename = "upload_#{SecureRandom.hex(6)}#{ext}"
        end
        content_type = "application/octet-stream" if content_type.blank?

        io = StringIO.new(binary_data)

        target_assoc = @record.public_send(@association)

        if @replace
          if target_assoc.respond_to?(:purge) && target_assoc.attached?
            target_assoc.purge
          elsif target_assoc.respond_to?(:attached?) && target_assoc.attached?
            target_assoc.purge
          end
        end

        target_assoc.attach(
          io: io,
          filename: filename,
          content_type: content_type
        )

        true
      end
    end
  end
end
