class AddSeoMetadataToMacronCmsArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :macron_cms_articles, :meta_title, :string
    add_column :macron_cms_articles, :meta_description, :text
  end
end
