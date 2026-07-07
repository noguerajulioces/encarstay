class CreatePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :photos do |t|
      t.references :property, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string :caption

      t.timestamps
    end
  end
end
