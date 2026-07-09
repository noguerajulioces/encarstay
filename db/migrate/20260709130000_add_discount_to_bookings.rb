class AddDiscountToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :applied_discount_code, :string
    add_column :bookings, :discount_cents, :integer, null: false, default: 0
    add_index :bookings, :applied_discount_code
  end
end
