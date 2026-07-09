class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :property, null: false, foreign_key: true
      t.string  :reviewer_name, null: false
      t.string  :reviewer_location
      t.integer :rating, null: false
      t.text    :body
      t.date    :stayed_on

      t.timestamps
    end

    add_index :reviews, [ :property_id, :stayed_on ]
  end
end
