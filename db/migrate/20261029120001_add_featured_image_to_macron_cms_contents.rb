class AddFeaturedImageToMacronCmsContents < ActiveRecord::Migration[8.0]
  def change
    add_column :macron_cms_contents, :featured_image, :boolean, default: false, null: false
  end
end
