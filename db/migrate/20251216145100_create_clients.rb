class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone

      t.timestamps
    end

    add_index :clients, [ :shop_id, :name ]
  end
end
