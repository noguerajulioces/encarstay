class AddLocaleToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :locale, :string, default: "es", null: false
  end
end
