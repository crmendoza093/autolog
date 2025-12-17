class RenameServiceSuggestionsToServices < ActiveRecord::Migration[8.0]
  def change
    rename_table :service_suggestions, :services
  end
end
