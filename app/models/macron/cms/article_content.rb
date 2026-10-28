module Macron
  module Cms
    class ArticleContent < ApplicationRecord
      belongs_to :article, class_name: "Macron::Cms::Article"
      belongs_to :content, class_name: "Macron::Cms::Content"

      before_validation :assign_default_sort_order, on: :create

      validates :sort_order, numericality: { only_integer: true }

      default_scope -> { order(:sort_order, :id) }

      def filter_payload(raw_payload)
        return {} unless content && raw_payload.respond_to?(:to_h)

        allowed = content.field_names
        raw_payload.to_h.stringify_keys.slice(*allowed)
      end

      private

      def assign_default_sort_order
        return if sort_order.present? && sort_order != 0
        return unless article

        max_order = article.article_contents.unscoped.where(article_id: article.id).maximum(:sort_order)
        self.sort_order = max_order ? max_order + 1 : 1
      end
    end
  end
end
