module Macron
  module Cms
    module SeoHelper
      def cms_seo_meta(record, canonical_url: nil)
        return if record.nil?

        title = if record.respond_to?(:seo_title)
          record.seo_title
        elsif record.respond_to?(:title)
          record.title
        end

        description = if record.respond_to?(:seo_description)
          record.seo_description
        elsif record.respond_to?(:meta_description)
          record.meta_description.presence
        end

        canonical = canonical_url || (respond_to?(:request) && request.respond_to?(:original_url) ? request.original_url : nil)

        content_for(:title, title) if title.present?

        content_for(:head) do
          tags = []
          tags << tag.meta(name: "description", content: description) if description.present?
          tags << tag.link(rel: "canonical", href: canonical) if canonical.present?
          tags << tag.meta(property: "og:title", content: title) if title.present?
          tags << tag.meta(property: "og:description", content: description) if description.present?
          tags << tag.meta(property: "og:url", content: canonical) if canonical.present?
          safe_join(tags, "\n    ")
        end

        nil
      end
    end
  end
end
