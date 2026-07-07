class CreateCalendarSources < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_sources do |t|
      t.references :property, null: false, foreign_key: true
      t.string :name, null: false, default: "Airbnb"
      t.string :ical_url, null: false
      t.datetime :last_synced_at
      t.string :last_status
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
