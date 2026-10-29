class RemoveNameFromMacronCmsArticles < ActiveRecord::Migration[8.0]
  def change
    remove_index :macron_cms_articles, :name, unique: true, if_exists: true
    remove_column :macron_cms_articles, :name, :string
  end
end
