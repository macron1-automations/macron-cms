class CreateMacronCmsContents < ActiveRecord::Migration[8.0]
  def change
    create_table :macron_cms_contents do |t|
      t.string :name, null: false
      t.jsonb :fields, default: {}, null: false
      t.jsonb :payload, default: {}, null: false

      t.timestamps
    end

    add_index :macron_cms_contents, :name, unique: true
  end
end
