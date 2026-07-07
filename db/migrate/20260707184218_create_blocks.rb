class CreateBlocks < ActiveRecord::Migration[8.1]
  def change
    create_table :blocks do |t|
      t.references :property, null: false, foreign_key: true
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.string :reason

      t.timestamps
    end
    add_index :blocks, [ :property_id, :starts_on, :ends_on ]
  end
end
