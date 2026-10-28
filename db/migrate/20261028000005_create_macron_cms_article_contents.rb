class CreateMacronCmsArticleContents < ActiveRecord::Migration[8.0]
  def change
    create_table :macron_cms_article_contents do |t|
      t.references :article, null: false, foreign_key: { to_table: :macron_cms_articles }
      t.references :content, null: false, foreign_key: { to_table: :macron_cms_contents }
      t.integer :sort_order, default: 0, null: false

      t.timestamps
    end

    add_index :macron_cms_article_contents, [ :article_id, :sort_order ]
  end
end
