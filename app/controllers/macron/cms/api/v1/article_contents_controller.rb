module Macron
  module Cms
    module Api
      module V1
        class ArticleContentsController < BaseController
          include Macron::Cms::ApiSerialization

          before_action :set_article
          before_action :set_article_content, only: %i[update destroy move convert]

          def create
            content_type_name = params[:content_type] || params.dig(:content_block, :content_type)
            content_type = Content.find_by(name: content_type_name.to_s.strip)

            if content_type.nil?
              render json: { errors: [ "Unknown content type: '#{content_type_name}'. Available types: #{Content.pluck(:name).join(', ')}" ] },
                     status: :unprocessable_entity
              return
            end

            insert_at = (params[:insert_at] || params.dig(:content_block, :insert_at)).presence&.to_i
            raw_payload = clean_payload_param(params[:payload] || params.dig(:content_block, :payload))

            ActiveRecord::Base.transaction do
              if insert_at && insert_at >= 1
                @article.article_contents.where("sort_order >= ?", insert_at).update_all("sort_order = sort_order + 1")
                @article_content = @article.article_contents.build(content: content_type, sort_order: insert_at)
              else
                @article_content = @article.article_contents.build(content: content_type)
              end

              @article_content.payload = @article_content.filter_payload(raw_payload)
              @article_content.save!

              attach_file_to_block!(@article_content)
              normalize_sort_orders!(@article)
              @article.sync_featured_image!
            end

            render json: {
              content_block: serialize_content_block(@article_content),
              article_id: @article.id,
              blocks_count: @article.article_contents.count
            }, status: :created
          rescue ArgumentError => e
            render json: { errors: [ e.message ] }, status: :unprocessable_entity
          rescue ActiveRecord::RecordInvalid => e
            render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
          end

          def update
            ActiveRecord::Base.transaction do
              target_type_name = params[:content_type] || params.dig(:content_block, :content_type)
              if target_type_name.present? && target_type_name != @article_content.content.name
                target_type = Content.find_by(name: target_type_name.to_s.strip)
                if target_type.nil?
                  render json: { errors: [ "Unknown content type: '#{target_type_name}'" ] }, status: :unprocessable_entity
                  return
                end
                @article_content.content = target_type
              end

              raw_payload = params[:payload] || params.dig(:content_block, :payload)
              if raw_payload.present?
                filtered = @article_content.filter_payload(clean_payload_param(raw_payload))
                replace_payload = ActiveModel::Type::Boolean.new.cast(params[:replace_payload] || params.dig(:content_block, :replace_payload))
                @article_content.payload = replace_payload ? filtered : (@article_content.payload || {}).merge(filtered)
              end

              purge = ActiveModel::Type::Boolean.new.cast(params[:purge_attachment] || params.dig(:content_block, :purge_attachment))
              if purge && @article_content.files.attached?
                @article_content.files.purge
              end

              @article_content.save!
              attach_file_to_block!(@article_content)
              @article.sync_featured_image!
            end

            render json: { content_block: serialize_content_block(@article_content) }, status: :ok
          rescue ArgumentError => e
            render json: { errors: [ e.message ] }, status: :unprocessable_entity
          rescue ActiveRecord::RecordInvalid => e
            render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
          end

          def destroy
            ActiveRecord::Base.transaction do
              id = @article_content.id
              @article_content.destroy!
              normalize_sort_orders!(@article)
              @article.sync_featured_image!
              render json: { deleted: true, id: id }, status: :ok
            end
          end

          def reorder
            ordered_ids = Array(params[:ordered_ids] || params[:ordered_block_ids]).map(&:to_i)
            if ordered_ids.empty?
              render json: { errors: [ "ordered_ids must be a non-empty array of block IDs" ] }, status: :unprocessable_entity
              return
            end

            existing_blocks = @article.article_contents.index_by(&:id)
            missing_ids = ordered_ids - existing_blocks.keys
            if missing_ids.any?
              render json: { errors: [ "Blocks not found on article: #{missing_ids.join(', ')}" ] }, status: :unprocessable_entity
              return
            end

            full_order = ordered_ids + (existing_blocks.keys - ordered_ids)
            ActiveRecord::Base.transaction do
              full_order.each_with_index do |id, idx|
                existing_blocks[id].update_column(:sort_order, idx + 1)
              end
              @article.sync_featured_image!
            end

            @article.reload
            blocks = @article.article_contents.includes(:content, files_attachments: :blob).order(:sort_order, :id)
            render json: { content_blocks: serialize_blocks_collection(blocks) }, status: :ok
          end

          def move
            ordered = @article.article_contents.order(:sort_order, :id).to_a
            current_index = ordered.index(@article_content)

            target_index = nil
            if params[:direction].present?
              direction = params[:direction].to_s.downcase
              target_index = direction == "up" ? current_index - 1 : current_index + 1
            elsif params[:position].present?
              target_index = params[:position].to_i - 1
            end

            if target_index && target_index >= 0 && target_index < ordered.length
              ordered.delete_at(current_index)
              ordered.insert(target_index, @article_content)
              ActiveRecord::Base.transaction do
                ordered.each_with_index do |item, idx|
                  item.update_column(:sort_order, idx + 1)
                end
                @article.sync_featured_image!
              end
            end

            @article.reload
            blocks = @article.article_contents.includes(:content, files_attachments: :blob).order(:sort_order, :id)
            render json: { content_blocks: serialize_blocks_collection(blocks) }, status: :ok
          end

          def convert
            target_name = params[:target_content_type] || params.dig(:content_block, :target_content_type)
            target_content = Content.find_by(name: target_name.to_s.strip) || Content.find_by(id: params[:target_content_id])

            if target_content.nil?
              render json: { errors: [ "Target content type '#{target_name}' not found" ] }, status: :unprocessable_entity
              return
            end

            if @article_content.convert_to(target_content)
              @article.sync_featured_image!
              render json: { content_block: serialize_content_block(@article_content) }, status: :ok
            else
              render json: { errors: @article_content.errors.full_messages }, status: :unprocessable_entity
            end
          end

          private

          def set_article
            @article = Article.friendly.find(params[:article_id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Article not found" }, status: :not_found
          end

          def set_article_content
            @article_content = @article.article_contents.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Content block not found" }, status: :not_found
          end

          def clean_payload_param(raw)
            if raw.respond_to?(:permit!)
              raw.permit!.to_h
            elsif raw.respond_to?(:to_unsafe_h)
              raw.to_unsafe_h
            elsif raw.respond_to?(:to_h)
              raw.to_h
            else
              {}
            end
          end

          def attach_file_to_block!(article_content)
            file_upload = params[:file_upload] || params.dig(:content_block, :file_upload) ||
                          params[:upload_data] || params.dig(:content_block, :upload_data)
            if file_upload.present?
              InlineAssetAttacher.attach(article_content: article_content, upload_data: file_upload, replace: true)
              return
            end

            remote_url = params[:image_url] || params[:file_url] || params[:upload_url] ||
                         params.dig(:content_block, :image_url) || params.dig(:content_block, :file_url) ||
                         params.dig(:payload, :upload) || params.dig(:content_block, :payload, :upload)

            if remote_url.present?
              article_content.payload ||= {}
              article_content.payload["upload"] = remote_url
              article_content.save!

              if remote_url.start_with?("http://") || remote_url.start_with?("https://")
                RemoteAssetAttacher.attach(article_content: article_content, url: remote_url, replace: true)
              end
            end
          end
        end
      end
    end
  end
end
