module Macron
  module Cms
    module Api
      module V1
        class ArticlesController < BaseController
          include Macron::Cms::ApiSerialization

          before_action :set_article, only: %i[show update destroy]

          def index
            articles = Article.all
            if params[:q].present?
              query = "%#{params[:q].to_s.strip.downcase}%"
              articles = articles.where(
                "LOWER(title) LIKE :q OR LOWER(slug) LIKE :q OR LOWER(COALESCE(meta_title, '')) LIKE :q OR LOWER(COALESCE(meta_description, '')) LIKE :q",
                q: query
              )
            end

            page = [ params[:page].to_i, 1 ].max
            per_page = params[:per_page].present? ? [ [ params[:per_page].to_i, 1 ].max, 100 ].min : 20
            total_count = articles.count
            total_pages = (total_count.to_f / per_page).ceil

            include_blocks = ActiveModel::Type::Boolean.new.cast(params[:include_blocks])

            scope = articles.includes(:featured_image_blob, background_image_attachment: :blob)
            scope = scope.includes(article_contents: [ :content, files_attachments: :blob ]) if include_blocks

            records = scope.offset((page - 1) * per_page).limit(per_page)

            serialized = records.map do |art|
              data = serialize_article(art)
              if include_blocks
                data[:content_blocks] = serialize_blocks_collection(art.article_contents.order(:sort_order, :id))
              end
              data
            end

            render json: {
              articles: serialized,
              meta: {
                page: page,
                per_page: per_page,
                total_count: total_count,
                total_pages: total_pages
              }
            }
          end

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

            was_new_record = @article.new_record?
            @article.assign_attributes(article_attributes)

            ActiveRecord::Base.transaction do
              unless @article.save
                render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
                return
              end

              handle_background_image!(@article)

              if params.key?(:content_blocks)
                sync_content_blocks!(@article, params[:content_blocks])
              end

              @article.sync_featured_image!
            end

            status = was_new_record ? :created : :ok
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

              handle_background_image!(@article)

              if params.key?(:content_blocks)
                sync_content_blocks!(@article, params[:content_blocks])
              end

              @article.sync_featured_image!
            end

            render json: serialize_article_with_blocks(@article), status: :ok
          rescue ArgumentError => e
            render json: { errors: [ e.message ] }, status: :unprocessable_entity
          rescue ActiveRecord::RecordInvalid => e
            render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
          end

          def destroy
            id = @article.id
            slug = @article.slug
            @article.destroy!
            render json: { deleted: true, id: id, slug: slug }, status: :ok
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

          def handle_background_image!(article)
            raw = params[:article].presence || params

            purge = ActiveModel::Type::Boolean.new.cast(raw[:purge_background_image] || params[:purge_background_image])
            if purge && article.background_image.attached?
              article.background_image.purge
            end

            bg_upload = raw[:background_image_upload] || params[:background_image_upload]
            if bg_upload.present?
              InlineAssetAttacher.attach_background(article: article, upload_data: bg_upload, replace: true)
              return
            end

            bg_url = raw[:background_image_url] || params[:background_image_url]
            if bg_url.present?
              RemoteAssetAttacher.attach_background(article: article, url: bg_url, replace: true)
            end
          end

          def sync_content_blocks!(article, blocks_params)
            return unless blocks_params.is_a?(Array)

            existing_blocks = article.article_contents.index_by(&:id)
            seen_ids = []

            blocks_params.each_with_index do |block_data, index|
              raw_block = block_data.respond_to?(:to_unsafe_h) ? block_data.to_unsafe_h : block_data.to_h
              block_id = (raw_block["id"] || raw_block[:id]).presence&.to_i

              content_type_name = raw_block["content_type"] || raw_block[:content_type]
              content_type = Content.find_by(name: content_type_name.to_s.strip) if content_type_name.present?

              raw_payload = raw_block["payload"] || raw_block[:payload] || {}
              order = (raw_block["sort_order"] || raw_block[:sort_order]).presence || (index + 1)

              article_content = if block_id && existing_blocks.key?(block_id)
                seen_ids << block_id
                existing_blocks[block_id]
              else
                article.article_contents.build
              end

              if content_type
                article_content.content = content_type
              elsif article_content.new_record?
                raise ArgumentError, "Unknown content type: '#{content_type_name}'. Available types: #{Content.pluck(:name).join(', ')}"
              end

              article_content.sort_order = order.to_i

              filtered = article_content.filter_payload(raw_payload)
              replace_payload = ActiveModel::Type::Boolean.new.cast(raw_block["replace_payload"] || raw_block[:replace_payload])
              article_content.payload = if article_content.new_record? || replace_payload
                filtered
              else
                (article_content.payload || {}).merge(filtered)
              end

              # Check attachment purging
              purge = ActiveModel::Type::Boolean.new.cast(raw_block["purge_attachment"] || raw_block[:purge_attachment])
              if purge && article_content.files.attached?
                article_content.files.purge
              end

              # Check inline base64 upload
              file_upload = raw_block["file_upload"] || raw_block[:file_upload] || raw_block["upload_data"] || raw_block[:upload_data]
              if file_upload.present?
                article_content.save!
                InlineAssetAttacher.attach(article_content: article_content, upload_data: file_upload, replace: true)
              else
                # Check remote URL
                remote_url = raw_block["image_url"] || raw_block[:image_url] ||
                             raw_block["file_url"] || raw_block[:file_url] ||
                             raw_block["upload_url"] || raw_block[:upload_url] ||
                             raw_payload["upload"]

                if remote_url.present?
                  article_content.payload ||= {}
                  article_content.payload["upload"] = remote_url
                  article_content.save!

                  if remote_url.start_with?("http://") || remote_url.start_with?("https://")
                    RemoteAssetAttacher.attach(article_content: article_content, url: remote_url, replace: true)
                  end
                else
                  article_content.save!
                end
              end
            end

            # Remove omitted existing blocks
            blocks_to_destroy = existing_blocks.keys - seen_ids
            if blocks_to_destroy.any?
              article.article_contents.where(id: blocks_to_destroy).destroy_all
            end

            normalize_sort_orders!(article)
          end
        end
      end
    end
  end
end
