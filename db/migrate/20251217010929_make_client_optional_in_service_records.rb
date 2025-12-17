class MakeClientOptionalInServiceRecords < ActiveRecord::Migration[8.0]
  def change
    change_column_null :service_records, :client_id, true
  end
end
