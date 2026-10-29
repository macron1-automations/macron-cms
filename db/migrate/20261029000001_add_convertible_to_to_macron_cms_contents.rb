class AddConvertibleToToMacronCmsContents < ActiveRecord::Migration[8.0]
  def change
    add_column :macron_cms_contents, :convertible_to, :jsonb, default: [], null: false
  end
end
