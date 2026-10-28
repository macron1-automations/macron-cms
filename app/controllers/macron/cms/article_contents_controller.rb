module Macron
  module Cms
    class ArticleContentsController < ApplicationController
      before_action :set_article
      before_action :set_article_content, only: %i[update destroy move]

      def create
        content = Content.find(params.dig(:article_content, :content_id))
        @article_content = @article.article_contents.build(content: content)
        @article_content.payload = @article_content.filter_payload(payload_param)

        if @article_content.save
          redirect_to article_path(@article), notice: "Content block was successfully added."
        else
          redirect_to article_path(@article), alert: "Failed to add content block: #{@article_content.errors.full_messages.to_sentence}"
        end
      end

      def update
        filtered = @article_content.filter_payload(payload_param)
        if @article_content.update(payload: filtered)
          redirect_to article_path(@article), notice: "Content block was successfully updated."
        else
          redirect_to article_path(@article), alert: "Failed to update content block: #{@article_content.errors.full_messages.to_sentence}"
        end
      end

      def destroy
        @article_content.destroy
        normalize_sort_orders!
        redirect_to article_path(@article), notice: "Content block was successfully removed."
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

        redirect_to article_path(@article), notice: "Content block order updated."
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
          format.html { redirect_to article_path(@article), notice: "Content block order updated." }
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

      def normalize_sort_orders!
        @article.article_contents.order(:sort_order, :id).each_with_index do |item, idx|
          item.update_column(:sort_order, idx + 1)
        end
      end
    end
  end
end
