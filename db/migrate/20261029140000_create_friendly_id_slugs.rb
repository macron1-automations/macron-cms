class CreateFriendlyIdSlugs < ActiveRecord::Migration[8.0]
  def change
    create_table :friendly_id_slugs do |t|
      t.string   :slug,           null: false
      t.integer  :sluggable_id,   null: false
      t.string   :sluggable_type, limit: 50
      t.string   :scope
      t.datetime :created_at
    end

    add_index :friendly_id_slugs, [ :sluggable_type, :sluggable_id ]
    add_index :friendly_id_slugs, [ :slug, :sluggable_type ], length: { slug: 140, sluggable_type: 50 }
    add_index :friendly_id_slugs, [ :slug, :sluggable_type, :scope ], length: { slug: 70, sluggable_type: 50, scope: 70 }, unique: true

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO friendly_id_slugs (slug, sluggable_id, sluggable_type, created_at)
          SELECT slug, id, 'Macron::Cms::Article', CURRENT_TIMESTAMP
          FROM macron_cms_articles
          WHERE slug IS NOT NULL AND slug <> '';
        SQL
      end
    end
  end
end
