class AddPublishedAtToMacronCmsArticles < ActiveRecord::Migration[8.0]
  def up
    add_column :macron_cms_articles, :published_at, :datetime
    add_index :macron_cms_articles, :published_at

    Macron::Cms::Article.reset_column_information
    execute("UPDATE macron_cms_articles SET published_at = created_at WHERE published_at IS NULL")
  end

  def down
    remove_index :macron_cms_articles, :published_at, if_exists: true
    remove_column :macron_cms_articles, :published_at
  end
end
