class AddReviewAggregatesToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :reviews_count, :integer, null: false, default: 0
    add_column :properties, :rating_cache, :decimal, precision: 3, scale: 2
  end
end
