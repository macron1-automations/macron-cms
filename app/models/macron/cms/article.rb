module Macron
  module Cms
    class Article < ApplicationRecord
      VALID_BACKGROUND_REPEATS = %w[no-repeat repeat repeat-x repeat-y].freeze
      VALID_BACKGROUND_SIZES = %w[cover contain auto].freeze
      VALID_BACKGROUND_POSITIONS = %w[center top bottom left right].freeze
      VALID_BACKGROUND_ATTACHMENTS = %w[scroll fixed].freeze

      DEFAULT_BACKGROUND_REPEAT = "no-repeat"
      DEFAULT_BACKGROUND_SIZE = "cover"
      DEFAULT_BACKGROUND_POSITION = "center"
      DEFAULT_BACKGROUND_ATTACHMENT = "scroll"

      before_validation :normalize_and_derive_slug_and_name

      extend FriendlyId
      friendly_id :slug_candidate, use: %i[slugged history]

      validates :title, presence: true
      validates :name, presence: true, uniqueness: true
      validates :slug, presence: true, uniqueness: true

      def should_generate_new_friendly_id?
        slug_changed? || super
      end

      def slug_candidate
        slug.presence || name.presence || title
      end

      has_many :article_contents, -> { order(:sort_order) }, class_name: "Macron::Cms::ArticleContent", dependent: :destroy
      has_many :contents, through: :article_contents

      has_one_attached :background_image
      belongs_to :featured_image_blob, class_name: "ActiveStorage::Blob", optional: true

      def featured_image
        featured_image_blob
      end

      def sync_featured_image!
        return if destroyed? || marked_for_destruction?

        next_blob_id = article_contents
          .unscoped
          .where(article_id: id)
          .joins(:content, :files_attachments)
          .where(macron_cms_contents: { featured_image: true })
          .order(:sort_order, :id, Arel.sql("active_storage_attachments.id ASC"))
          .pick(Arel.sql("active_storage_attachments.blob_id"))

        if featured_image_blob_id != next_blob_id
          update_column(:featured_image_blob_id, next_blob_id)
          self.featured_image_blob_id = next_blob_id
        end
      end

      def seo_title
        meta_title.presence || title
      end

      def seo_description
        meta_description.presence
      end

      def normalized_background_options
        (background_options || {}).to_h.stringify_keys
      end

      def background_repeat
        val = normalized_background_options["repeat"].to_s.strip.presence
        VALID_BACKGROUND_REPEATS.include?(val) ? val : DEFAULT_BACKGROUND_REPEAT
      end

      def background_size
        val = normalized_background_options["size"].to_s.strip.presence
        VALID_BACKGROUND_SIZES.include?(val) ? val : DEFAULT_BACKGROUND_SIZE
      end

      def background_position
        val = normalized_background_options["position"].to_s.strip.presence
        VALID_BACKGROUND_POSITIONS.include?(val) ? val : DEFAULT_BACKGROUND_POSITION
      end

      def background_attachment
        val = normalized_background_options["attachment"].to_s.strip.presence
        VALID_BACKGROUND_ATTACHMENTS.include?(val) ? val : DEFAULT_BACKGROUND_ATTACHMENT
      end

      private

      def normalize_and_derive_slug_and_name
        self.slug = slug.to_s.parameterize.presence

        return if name.present? || (slug.blank? && title.blank?)

        base_name = title.to_s.parameterize.presence || slug.presence || "article"
        candidate = base_name
        scope = id.present? ? self.class.where.not(id: id) : self.class.all

        counter = 1
        while scope.exists?(name: candidate)
          counter += 1
          candidate = "#{base_name}-#{counter}"
        end

        self.name = candidate
      end
    end
  end
end
