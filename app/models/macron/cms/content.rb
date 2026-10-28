module Macron
  module Cms
    class Content < ApplicationRecord
      validates :name, presence: true, uniqueness: true

      has_many :article_contents, class_name: "Macron::Cms::ArticleContent", dependent: :destroy
      has_many :articles, through: :article_contents

      def normalized_fields
        raw = if fields.is_a?(Array)
          fields
        elsif fields.is_a?(Hash) && fields.present?
          [ fields ]
        else
          []
        end

        raw.filter_map do |f|
          next unless f.is_a?(Hash)

          fname = (f["name"] || f[:name]).to_s.strip
          next if fname.blank?

          fkind = (f["kind"] || f[:kind]).presence || "string"
          f.stringify_keys.merge("name" => fname, "kind" => fkind.to_s)
        end
      end

      def field_names
        normalized_fields.map { |f| f["name"] }
      end
    end
  end
end
