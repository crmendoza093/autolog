class CreateVehicles < ActiveRecord::Migration[8.0]
  def change
    create_table :vehicles do |t|
      t.references :client, null: false, foreign_key: true
      t.string :plate, null: false
      t.string :brand
      t.string :color
      t.string :model

      t.timestamps
    end

    add_index :vehicles, :plate, unique: true
  end
end
