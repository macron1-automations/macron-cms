class AddTextColorToMacronCmsArticles < ActiveRecord::Migration[8.0]
  def change
    add_column :macron_cms_articles, :text_color, :string
  end
end
