class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name_es
      t.string :name_en
      t.string :name_pt
      t.string :slug, null: false
      t.string :icon
      t.integer :position, default: 0, null: false

      t.timestamps
    end
    add_index :categories, :slug, unique: true
  end
end
