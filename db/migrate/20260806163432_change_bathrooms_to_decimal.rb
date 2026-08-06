class ChangeBathroomsToDecimal < ActiveRecord::Migration[8.1]
  # Medios baños (toilette sin ducha) cuentan 0,5 — ej.: el loft tiene 1,5.
  def up
    change_column :properties, :bathrooms, :decimal, precision: 3, scale: 1, default: 1, null: false
  end

  def down
    change_column :properties, :bathrooms, :integer, default: 1, null: false
  end
end
