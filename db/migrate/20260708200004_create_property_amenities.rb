class CreatePropertyAmenities < ActiveRecord::Migration[8.1]
  def change
    create_table :property_amenities do |t|
      t.references :property, null: false, foreign_key: true
      t.references :amenity, null: false, foreign_key: true

      t.timestamps
    end

    add_index :property_amenities, [ :property_id, :amenity_id ], unique: true
  end
end
