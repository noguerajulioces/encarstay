class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :category, foreign_key: true
      t.string :slug, null: false

      t.string :title_es
      t.string :title_en
      t.string :title_pt
      t.string :excerpt_es
      t.string :excerpt_en
      t.string :excerpt_pt
      t.string :meta_description_es
      t.string :meta_description_en
      t.string :meta_description_pt

      t.boolean :published, default: false, null: false
      t.boolean :featured, default: false, null: false
      t.datetime :published_at
      t.integer :position, default: 0, null: false

      t.timestamps
    end
    add_index :posts, :slug, unique: true
    add_index :posts, [ :published, :published_at ]
  end
end
