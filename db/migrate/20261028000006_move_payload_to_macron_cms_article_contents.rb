class MovePayloadToMacronCmsArticleContents < ActiveRecord::Migration[8.0]
  def change
    add_column :macron_cms_article_contents, :payload, :jsonb, default: {}, null: false
    remove_column :macron_cms_contents, :payload, :jsonb, default: {}, null: false
  end
end
