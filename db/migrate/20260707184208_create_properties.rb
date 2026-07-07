class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :address_area

      t.integer :capacity, null: false, default: 2
      t.integer :bedrooms, null: false, default: 1
      t.integer :beds, null: false, default: 1
      t.integer :bathrooms, null: false, default: 1

      t.integer :base_price_cents, null: false, default: 0
      t.string :currency, null: false, default: "PYG"
      t.integer :cleaning_fee_cents, null: false, default: 0
      t.integer :min_nights, null: false, default: 2

      t.boolean :active, null: false, default: true
      t.string :calendar_token, null: false

      t.timestamps
    end
    add_index :properties, :slug, unique: true
    add_index :properties, :calendar_token, unique: true
  end
end
