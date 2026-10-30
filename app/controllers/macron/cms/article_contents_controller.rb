module Macron
  module Cms
    class ArticleContentsController < ApplicationController
      before_action :set_article
      before_action :set_article_content, only: %i[update destroy move convert]

      def create
        content = Content.find(params.dig(:article_content, :content_id))
        insert_at = params.dig(:article_content, :insert_at).presence&.to_i

        saved = false
        ActiveRecord::Base.transaction do
          if insert_at && insert_at >= 1
            @article.article_contents.where("sort_order >= ?", insert_at).update_all("sort_order = sort_order + 1")
            @article_content = @article.article_contents.build(content: content, sort_order: insert_at)
          else
            @article_content = @article.article_contents.build(content: content)
          end

          @article_content.payload = @article_content.filter_payload(payload_param)
          attach_files_if_present!

          if @article_content.save
            normalize_sort_orders!
            saved = true
          else
            raise ActiveRecord::Rollback
          end
        end

        if saved
          respond_to do |format|
            format.turbo_stream do
              render_content_blocks_stream(
                notice: "Content block was successfully added.",
                newly_added_id: @article_content.id
              )
            end
            format.html { redirect_to article_path(@article, view: params[:view].presence), notice: "Content block was successfully added." }
          end
        else
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.update(
                "flash-messages",
                partial: "macron/cms/shared/flash",
                locals: { alert: "Failed to add content block: #{@article_content.errors.full_messages.to_sentence}" }
              )
            end
            format.html { redirect_to article_path(@article, view: params[:view].presence), alert: "Failed to add content block: #{@article_content.errors.full_messages.to_sentence}" }
          end
        end
      end

      def update
        filtered = @article_content.filter_payload(payload_param)
        remove_files = Array(params.dig(:article_content, :remove_files)).map(&:to_s)

        remove_files.each do |fname|
          filtered[fname] = nil
          if %w[upload file].include?(fname) && @article_content.files.attached?
            @article_content.files.purge
          end
        end

        @article_content.payload.each do |k, v|
          if filtered.key?(k) && filtered[k].blank? && v.present? && !remove_files.include?(k)
            filtered[k] = v
          end
        end

        attach_files_if_present! unless remove_files.include?("upload") || remove_files.include?("file")

        merged_payload = (@article_content.payload || {}).merge(filtered)

        if @article_content.update(payload: merged_payload)
          respond_to do |format|
            format.turbo_stream do
              render_content_blocks_stream(
                notice: "Content block was successfully updated.",
                updated_id: @article_content.id
              )
            end
            format.html { redirect_to article_path(@article, view: params[:view].presence), notice: "Content block was successfully updated." }
          end
        else
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.update(
                "flash-messages",
                partial: "macron/cms/shared/flash",
                locals: { alert: "Failed to update content block: #{@article_content.errors.full_messages.to_sentence}" }
              )
            end
            format.html { redirect_to article_path(@article, view: params[:view].presence), alert: "Failed to update content block: #{@article_content.errors.full_messages.to_sentence}" }
          end
        end
      end

      def destroy
        @article_content.destroy
        normalize_sort_orders!
        respond_to do |format|
          format.turbo_stream do
            render_content_blocks_stream(notice: "Content block was successfully removed.")
          end
          format.html { redirect_to article_path(@article, view: params[:view].presence), notice: "Content block was successfully removed." }
        end
      end

      def move
        direction = params[:direction].to_s
        ordered = @article.article_contents.order(:sort_order, :id).to_a
        current_index = ordered.index(@article_content)

        if current_index
          target_index = direction == "up" ? current_index - 1 : current_index + 1
          if target_index >= 0 && target_index < ordered.length
            # Swap
            ordered[current_index], ordered[target_index] = ordered[target_index], ordered[current_index]
            ActiveRecord::Base.transaction do
              ordered.each_with_index do |item, idx|
                item.update_column(:sort_order, idx + 1)
              end
            end
          end
        end

        respond_to do |format|
          format.turbo_stream do
            render_content_blocks_stream(notice: "Content block order updated.")
          end
          format.html { redirect_to article_path(@article, view: params[:view].presence), notice: "Content block order updated." }
        end
      end

      def convert
        target_content = Content.find_by(id: params[:target_content_id]) ||
                         Content.find_by(name: params[:target_content_type].to_s)

        if @article_content.convert_to(target_content)
          notice_msg = "Content block was converted to #{target_content.name}."
          respond_to do |format|
            format.turbo_stream do
              render_content_blocks_stream(
                notice: notice_msg,
                updated_id: @article_content.id
              )
            end
            format.html { redirect_to article_path(@article, view: params[:view].presence), notice: notice_msg }
          end
        else
          alert_msg = "Failed to convert content block: #{@article_content.errors.full_messages.to_sentence}"
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.update(
                "flash-messages",
                partial: "macron/cms/shared/flash",
                locals: { alert: alert_msg }
              )
            end
            format.html { redirect_to article_path(@article, view: params[:view].presence), alert: alert_msg }
          end
        end
      end

      def reorder
        ordered_ids = Array(params[:ordered_ids]).map(&:to_i)
        if ordered_ids.any?
          contents_by_id = @article.article_contents.index_by(&:id)
          ActiveRecord::Base.transaction do
            ordered_ids.each_with_index do |id, idx|
              item = contents_by_id[id]
              item.update_column(:sort_order, idx + 1) if item
            end
          end
        end

        respond_to do |format|
          format.json { render json: { status: "ok" } }
          format.html { redirect_to article_path(@article, view: params[:view].presence), notice: "Content block order updated." }
        end
      end

      private

      def set_article
        @article = Article.friendly.find(params[:article_id])
      end

      def set_article_content
        @article_content = @article.article_contents.find(params[:id])
      end

      def payload_param
        raw = params.dig(:article_content, :payload)
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

      def attach_files_if_present!
        payload = params.dig(:article_content, :payload)
        file_input = (payload && (payload[:upload] || payload["upload"])) ||
                     params.dig(:article_content, :upload) ||
                     params.dig(:article_content, :files)

        return unless file_input.present?

        @article_content.attach_upload(file_input, replace: true)
      end

      def normalize_sort_orders!
        @article.article_contents.unscoped.where(article_id: @article.id).order(:sort_order, :id).each_with_index do |item, idx|
          item.update_column(:sort_order, idx + 1)
        end
      end

      def render_content_blocks_stream(notice: nil, alert: nil, newly_added_id: nil, updated_id: nil)
        @content_types = Content.order(:name)
        compact = params[:view] == "compact"
        turbo_stream_actions = [
          turbo_stream.update(
            "content-blocks-section",
            partial: "macron/cms/articles/content_blocks_section",
            locals: {
              article: @article,
              article_contents: @article.article_contents.for_display.order(:sort_order, :id).load,
              content_types: @content_types,
              compact: compact,
              newly_added_id: newly_added_id,
              updated_id: updated_id
            }
          )
        ]

        if notice.present? || alert.present?
          turbo_stream_actions << turbo_stream.update(
            "flash-messages",
            partial: "macron/cms/shared/flash",
            locals: { notice: notice, alert: alert }
          )
        end

        render turbo_stream: turbo_stream_actions
      end
    end
  end
end
