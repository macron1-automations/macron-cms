module Macron
  module Cms
    module ApiSerialization
      extend ActiveSupport::Concern

      included do
        # Helpers available to controllers including this concern
      end

      def serialize_article(article)
        {
          id: article.id,
          title: article.title,
          slug: article.slug,
          published_at: article.published_at&.iso8601,
          meta_title: article.meta_title,
          meta_description: article.meta_description,
          background_color: article.background_color,
          text_color: article.text_color,
          background_options: article.background_options,
          featured_image: serialize_attachment_blob(article.featured_image),
          background_image: serialize_attachment_blob(article.background_image.attached? ? article.background_image.blob : nil),
          blocks_count: article.respond_to?(:blocks_count) ? article.blocks_count : article.article_contents.count,
          created_at: article.created_at&.iso8601,
          updated_at: article.updated_at&.iso8601
        }
      end

      def serialize_article_with_blocks(article)
        article.reload
        blocks = article.article_contents.includes(:content, files_attachments: :blob).order(:sort_order, :id)
        {
          article: serialize_article(article),
          content_blocks: serialize_blocks_collection(blocks)
        }
      end

      def serialize_blocks_collection(blocks)
        blocks.map { |block| serialize_content_block(block) }
      end

      def serialize_content_block(block)
        data = {
          id: block.id,
          content_type: block.content&.name,
          sort_order: block.sort_order,
          payload: block.payload
        }

        if block.files.attached?
          file = block.files.first
          data[:attached_file] = serialize_attachment_blob(file)
        end

        data
      end

      def serialize_attachment_blob(blob_or_attachment)
        return nil if blob_or_attachment.nil?

        blob = blob_or_attachment.respond_to?(:blob) ? blob_or_attachment.blob : blob_or_attachment
        return nil unless blob

        {
          filename: blob.filename.to_s,
          content_type: blob.content_type,
          byte_size: blob.byte_size,
          url: Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
        }
      end

      def normalize_sort_orders!(article)
        article.article_contents.unscoped.where(article_id: article.id).order(:sort_order, :id).each_with_index do |item, idx|
          item.update_column(:sort_order, idx + 1)
        end
      end
    end
  end
end
