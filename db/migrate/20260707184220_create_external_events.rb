class CreateExternalEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :external_events do |t|
      t.references :calendar_source, null: false, foreign_key: true
      t.string :uid, null: false
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.string :summary
      t.text :raw_payload

      t.timestamps
    end
    add_index :external_events, [ :calendar_source_id, :uid ], unique: true
    add_index :external_events, [ :calendar_source_id, :starts_on, :ends_on ]
  end
end
