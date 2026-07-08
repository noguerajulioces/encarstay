class CreateGuideEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :guide_entries do |t|
      t.string :kind, null: false, default: "attraction"
      t.references :category, foreign_key: true
      t.string :slug, null: false

      t.string :title_es
      t.string :title_en
      t.string :title_pt
      t.string :summary_es
      t.string :summary_en
      t.string :summary_pt
      t.text :description_es
      t.text :description_en
      t.text :description_pt
      t.string :schedule_note_es
      t.string :schedule_note_en
      t.string :schedule_note_pt

      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :recurring, default: false, null: false

      t.string :address
      t.string :area
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :external_url

      t.boolean :featured, default: false, null: false
      t.boolean :published, default: false, null: false
      t.integer :position, default: 0, null: false

      t.timestamps
    end
    add_index :guide_entries, :slug, unique: true
    add_index :guide_entries, [ :kind, :published ]
    add_index :guide_entries, [ :kind, :featured ]
    add_index :guide_entries, :starts_at
  end
end
