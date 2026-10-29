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

      def normalized_convertible_to
        Array(convertible_to).filter_map do |entry|
          target_name = entry.to_s.strip
          target_name if target_name.present? && target_name != name
        end.uniq
      end

      def convertible_to?(target)
        target_name = target.is_a?(Content) ? target.name : target.to_s.strip
        normalized_convertible_to.include?(target_name)
      end

      def convertible_targets(available_contents = nil)
        names = normalized_convertible_to
        return [] if names.empty?

        indexed = if available_contents
          available_contents.index_by(&:name)
        else
          Content.where(name: names).index_by(&:name)
        end

        names.filter_map { |n| indexed[n] }
      end
    end
  end
end
