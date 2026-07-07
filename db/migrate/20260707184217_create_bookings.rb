class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.references :property, null: false, foreign_key: true
      t.string :code, null: false

      t.date :check_in, null: false
      t.date :check_out, null: false
      t.integer :guests_count, null: false, default: 1

      t.string :guest_name, null: false
      t.string :guest_email, null: false
      t.string :guest_phone
      t.text :notes

      t.string :status, null: false, default: "pending"
      t.string :source, null: false, default: "direct"

      t.integer :subtotal_cents, null: false, default: 0
      t.integer :cleaning_fee_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.string :currency, null: false, default: "PYG"

      t.datetime :confirmed_at
      t.datetime :cancelled_at

      t.timestamps
    end
    add_index :bookings, :code, unique: true
    add_index :bookings, [ :property_id, :status, :check_in, :check_out ]
  end
end
