class AddBackgroundFieldsToMacronCmsArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :macron_cms_articles, :background_color, :string
    add_column :macron_cms_articles, :background_options, :jsonb, default: {}, null: false
  end
end
