class CreateCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :campaigns do |t|
      t.string :subject, null: false
      t.string :status, null: false, default: "draft" # draft / sending / sent
      t.integer :recipients_count, null: false, default: 0
      t.datetime :sent_at

      t.timestamps
    end
  end
end
