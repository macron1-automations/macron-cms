class CreateMacronCmsArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :macron_cms_articles do |t|
      t.string :title, null: false

      t.timestamps
    end
  end
end
