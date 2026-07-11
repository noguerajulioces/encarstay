class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.string :whatsapp_number

      t.timestamps
    end
  end
end
