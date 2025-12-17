class CreateAnalyticsEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :analytics_events do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :metadata, default: {}

      t.datetime :created_at, null: false
    end

    add_index :analytics_events, :event_type
    add_index :analytics_events, :created_at
  end
end
