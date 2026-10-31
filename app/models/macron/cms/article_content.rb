module Macron
  module Cms
    class ArticleContent < ApplicationRecord
      belongs_to :article, class_name: "Macron::Cms::Article", touch: true
      belongs_to :content, class_name: "Macron::Cms::Content"

      has_many_attached :files

      after_save :sync_article_featured_image
      after_destroy :sync_article_featured_image, unless: -> { destroyed_by_association.present? }

      before_validation :assign_default_sort_order, on: :create

      validates :sort_order, numericality: { only_integer: true }

      default_scope -> { order(:sort_order, :id) }

      scope :for_display, -> { with_attached_files.includes(:content) }

      def upload
        files.first
      end

      def file
        files.first
      end

      def uploads
        files
      end

      def attach_upload(uploaded, replace: false)
        return unless uploaded.present?

        if replace && files.attached?
          files.purge
        end

        files.attach(uploaded)
      end

      def filter_payload(raw_payload)
        return {} unless content && raw_payload.respond_to?(:to_h)

        allowed = content.field_names
        raw_payload.to_h.stringify_keys.slice(*allowed).transform_values do |val|
          if val.respond_to?(:original_filename)
            val.original_filename
          elsif val.is_a?(Array) && val.any? { |v| v.respond_to?(:original_filename) }
            val.filter_map { |v| v.respond_to?(:original_filename) ? v.original_filename : v }
          else
            val
          end
        end
      end

      def convert_to(target_content)
        unless target_content.is_a?(Content) && content&.convertible_to?(target_content)
          errors.add(:base, "Cannot convert #{content&.name || 'unknown'} block to #{target_content&.name || 'unknown'}")
          return false
        end

        updated_payload = (payload || {}).deep_dup
        if files.attached? && updated_payload["upload"].blank? &&
           target_content.normalized_fields.any? { |f| f["name"] == "upload" && f["kind"] == "file" }
          updated_payload["upload"] = upload.filename.to_s
        end

        update(content: target_content, payload: updated_payload)
      end

      private

      def assign_default_sort_order
        return if sort_order.present? && sort_order != 0
        return unless article

        max_order = article.article_contents.unscoped.where(article_id: article.id).maximum(:sort_order)
        self.sort_order = max_order ? max_order + 1 : 1
      end

      def sync_article_featured_image
        article&.sync_featured_image!
      end
    end
  end
end
