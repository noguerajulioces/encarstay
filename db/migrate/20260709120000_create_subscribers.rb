class CreateSubscribers < ActiveRecord::Migration[8.1]
  def change
    create_table :subscribers do |t|
      t.string :email, null: false
      t.string :locale, null: false, default: "es"
      t.string :status, null: false, default: "pending" # pending / confirmed / unsubscribed
      t.string :source                                   # footer / popup
      t.string :confirmation_token
      t.string :unsubscribe_token
      t.datetime :confirmed_at
      t.datetime :unsubscribed_at
      t.string :discount_code
      t.datetime :discount_redeemed_at

      t.timestamps
    end

    add_index :subscribers, :email, unique: true
    add_index :subscribers, :confirmation_token, unique: true
    add_index :subscribers, :unsubscribe_token, unique: true
    add_index :subscribers, :discount_code, unique: true, where: "discount_code IS NOT NULL"
    add_index :subscribers, :status
  end
end
