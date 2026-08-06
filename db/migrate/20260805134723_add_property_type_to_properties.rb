class AddPropertyTypeToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :property_type, :string
  end
end
