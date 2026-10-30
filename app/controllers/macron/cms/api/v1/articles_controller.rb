module Macron
  module Cms
    module Api
      module V1
        class ArticlesController < BaseController
          before_action :set_article, only: %i[show update]

          def show
            render json: serialize_article_with_blocks(@article)
          end

          def create
            upsert_mode = ActiveModel::Type::Boolean.new.cast(params[:upsert])
            article_attributes = article_params

            @article = if upsert_mode
              find_existing_article(article_attributes) || Article.new
            else
              Article.new
            end

            @article.assign_attributes(article_attributes)

            ActiveRecord::Base.transaction do
              unless @article.save
                render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
                return
              end

              if params.key?(:content_blocks)
                sync_content_blocks!(@article, params[:content_blocks])
              end
            end

            status = @article.previously_new_record? ? :created : :ok
            render json: serialize_article_with_blocks(@article), status: status
          rescue ArgumentError => e
            render json: { errors: [ e.message ] }, status: :unprocessable_entity
          rescue ActiveRecord::RecordInvalid => e
            render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
          end

          def update
            ActiveRecord::Base.transaction do
              unless @article.update(article_params)
                render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
                return
              end

              if params.key?(:content_blocks)
                sync_content_blocks!(@article, params[:content_blocks])
              end
            end

            render json: serialize_article_with_blocks(@article), status: :ok
          rescue ArgumentError => e
            render json: { errors: [ e.message ] }, status: :unprocessable_entity
          rescue ActiveRecord::RecordInvalid => e
            render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
          end

          private

          def set_article
            @article = Article.friendly.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Article not found" }, status: :not_found
          end

          def find_existing_article(attrs)
            if attrs[:slug].present?
              existing = Article.find_by(slug: attrs[:slug])
              return existing if existing
            end

            if attrs[:title].present?
              existing = Article.find_by(title: attrs[:title])
              return existing if existing
            end

            nil
          end

          def article_params
            raw = params[:article].presence || params
            raw.permit(
              :title,
              :slug,
              :published_at,
              :meta_title,
              :meta_description,
              :background_color,
              :text_color,
              background_options: %i[repeat size position attachment]
            )
          end

          def sync_content_blocks!(article, blocks_params)
            return unless blocks_params.is_a?(Array)

            # Cleanly replace existing content blocks
            article.article_contents.destroy_all

            blocks_params.each_with_index do |block_data, index|
              raw_block = block_data.respond_to?(:to_unsafe_h) ? block_data.to_unsafe_h : block_data.to_h
              content_type_name = raw_block["content_type"] || raw_block[:content_type]
              content_type = Content.find_by(name: content_type_name.to_s.strip)

              if content_type.nil?
                raise ArgumentError, "Unknown content type: '#{content_type_name}'. Available types: #{Content.pluck(:name).join(', ')}"
              end

              raw_payload = raw_block["payload"] || raw_block[:payload] || {}
              remote_url = raw_block["image_url"] || raw_block[:image_url] ||
                           raw_block["file_url"] || raw_block[:file_url] ||
                           raw_block["upload_url"] || raw_block[:upload_url] ||
                           raw_payload["upload"]

              order = (raw_block["sort_order"] || raw_block[:sort_order]).presence || (index + 1)

              article_content = article.article_contents.build(
                content: content_type,
                sort_order: order.to_i
              )
              article_content.payload = article_content.filter_payload(raw_payload)

              if remote_url.present?
                article_content.payload["upload"] = remote_url
              end

              article_content.save!

              if remote_url.present? && (remote_url.start_with?("http://") || remote_url.start_with?("https://"))
                RemoteAssetAttacher.attach(article_content: article_content, url: remote_url)
              end
            end
          end

          def serialize_article_with_blocks(article)
            article.reload
            {
              article: {
                id: article.id,
                title: article.title,
                slug: article.slug,
                published_at: article.published_at&.iso8601,
                meta_title: article.meta_title,
                meta_description: article.meta_description,
                background_color: article.background_color,
                text_color: article.text_color,
                background_options: article.background_options,
                featured_image: serialize_featured_image(article),
                created_at: article.created_at&.iso8601,
                updated_at: article.updated_at&.iso8601
              },
              content_blocks: article.article_contents.includes(:content).order(:sort_order, :id).map do |ac|
                block_data = {
                  id: ac.id,
                  content_type: ac.content.name,
                  sort_order: ac.sort_order,
                  payload: ac.payload
                }

                if ac.files.attached?
                  file = ac.files.first
                  block_data[:attached_file] = {
                    filename: file.filename.to_s,
                    content_type: file.content_type,
                    byte_size: file.byte_size,
                    url: Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
                  }
                end

                block_data
              end
            }
          end

          def serialize_featured_image(article)
            return nil unless article.featured_image.present?

            file = article.featured_image
            {
              filename: file.filename.to_s,
              content_type: file.content_type,
              byte_size: file.byte_size,
              url: Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
            }
          end
        end
      end
    end
  end
end
