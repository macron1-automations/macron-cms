class AddNameAndSlugToMacronCmsArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :macron_cms_articles, :name, :string, null: false
    add_column :macron_cms_articles, :slug, :string, null: false
    add_index :macron_cms_articles, :name, unique: true
    add_index :macron_cms_articles, :slug, unique: true
  end
end
