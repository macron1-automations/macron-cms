class AddFeaturedImageBlobToMacronCmsArticles < ActiveRecord::Migration[8.0]
  def change
    add_reference :macron_cms_articles,
                  :featured_image_blob,
                  null: true,
                  foreign_key: { to_table: :active_storage_blobs, on_delete: :nullify }
  end
end
