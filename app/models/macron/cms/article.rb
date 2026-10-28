module Macron
  module Cms
    class Article < ApplicationRecord
      extend FriendlyId
      friendly_id :name, use: :slugged

      validates :title, presence: true
      validates :name, presence: true, uniqueness: true

      def seo_title
        meta_title.presence || title
      end

      def seo_description
        meta_description.presence
      end
    end
  end
end
