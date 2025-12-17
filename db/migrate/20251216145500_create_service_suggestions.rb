class CreateServiceSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :service_suggestions do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :service_name, null: false
      t.decimal :default_price, precision: 10, scale: 2, null: false
      t.integer :usage_count, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :service_suggestions, [ :shop_id, :active ]
    add_index :service_suggestions, :usage_count
  end
end
