class AddDistanceColumnsToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :distance_center_km, :decimal, precision: 5, scale: 1
    add_column :properties, :distance_costanera_km, :decimal, precision: 5, scale: 1
  end
end
