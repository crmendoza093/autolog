class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :state, null: false, default: "idle"
      t.jsonb :payload, default: {}
      t.datetime :last_activity_at

      t.timestamps
    end

    add_index :conversations, :state
    add_index :conversations, :last_activity_at
  end
end
