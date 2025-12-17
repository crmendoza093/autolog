class RenameServicesColumns < ActiveRecord::Migration[8.0]
  def change
    rename_column :services, :service_name, :name
    rename_column :services, :default_price, :price
  end
end
