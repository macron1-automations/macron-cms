module Macron
  module Cms
    module SlugRedirectable
      extend ActiveSupport::Concern

      private

      def redirect_to_canonical_slug_if_needed(record = @article)
        return false unless record.respond_to?(:slug)

        requested_identifier = params[:id].to_s
        return false if requested_identifier.blank?

        if requested_identifier != record.slug.to_s
          redirect_to default_canonical_path_for(record), status: :moved_permanently
          return true
        end

        false
      end

      def default_canonical_path_for(record)
        url_for(params.permit!.to_h.merge(id: record.slug, only_path: true))
      end
    end
  end
end
