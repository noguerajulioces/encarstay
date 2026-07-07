class CreateSeasonalRates < ActiveRecord::Migration[8.1]
  def change
    create_table :seasonal_rates do |t|
      t.references :property, null: false, foreign_key: true
      t.string :name, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.integer :price_per_night_cents, null: false, default: 0
      t.integer :min_nights

      t.timestamps
    end
    add_index :seasonal_rates, [ :property_id, :starts_on, :ends_on ]
  end
end
