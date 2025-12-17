class CreateServiceRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :service_records do |t|
      t.references :shop, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :vehicle, null: true, foreign_key: true
      t.string :service_name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.text :notes
      t.datetime :service_date, null: false

      t.timestamps
    end

    add_index :service_records, [ :shop_id, :service_date ]
    add_index :service_records, :created_at
  end
end
