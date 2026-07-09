class CreateAmenities < ActiveRecord::Migration[8.1]
  def change
    create_table :amenities do |t|
      t.string  :key, null: false
      t.string  :icon
      t.string  :category
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :amenities, :key, unique: true
  end
end
