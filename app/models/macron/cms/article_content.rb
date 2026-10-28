module Macron
  module Cms
    class ArticleContent < ApplicationRecord
      belongs_to :article, class_name: "Macron::Cms::Article"
      belongs_to :content, class_name: "Macron::Cms::Content"

      validates :sort_order, numericality: { only_integer: true }

      default_scope -> { order(:sort_order) }
    end
  end
end
