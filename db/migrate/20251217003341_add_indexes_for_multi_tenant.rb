class AddIndexesForMultiTenant < ActiveRecord::Migration[8.0]
  def change
    # Performance indexes for multi-tenant queries
    add_index :service_records, [ :shop_id, :service_date ], name: 'index_service_records_on_shop_and_date'
    add_index :clients, [ :shop_id, :name ], name: 'index_clients_on_shop_and_name'
    add_index :services, [ :shop_id, :name ], name: 'index_services_on_shop_and_name'

    # Ensure uniqueness of service names per shop
    add_index :services, [ :shop_id, :name ], unique: true, name: 'index_services_on_shop_and_name_unique'
  end
end
