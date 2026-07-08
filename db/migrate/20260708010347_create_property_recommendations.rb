class CreatePropertyRecommendations < ActiveRecord::Migration[8.1]
  def change
    create_table :property_recommendations do |t|
      t.references :guide_entry, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.integer :position, default: 0, null: false

      t.timestamps
    end
    add_index :property_recommendations, [ :guide_entry_id, :property_id ], unique: true
  end
end
