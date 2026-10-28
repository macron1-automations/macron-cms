module Macron
  module Cms
    class Article < ApplicationRecord
      before_validation :derive_name_from_title

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

      private

      def derive_name_from_title
        return if name.present? || title.blank?

        base = title.parameterize.presence || "article"
        candidate = base
        scope = id.present? ? self.class.where.not(id: id) : self.class.all

        counter = 1
        while scope.exists?(name: candidate)
          counter += 1
          candidate = "#{base}-#{counter}"
        end

        self.name = candidate
      end
    end
  end
end
