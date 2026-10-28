module Macron
  module Cms
    class Article < ApplicationRecord
      extend FriendlyId
      friendly_id :name, use: :slugged

      validates :title, presence: true
      validates :name, presence: true, uniqueness: true

      has_many :article_contents, -> { order(:sort_order) }, class_name: "Macron::Cms::ArticleContent", dependent: :destroy
      has_many :contents, through: :article_contents

      def seo_title
        meta_title.presence || title
      end

      def seo_description
        meta_description.presence
      end
    end
  end
end
