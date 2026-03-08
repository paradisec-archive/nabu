class MakeIdentifierRequiredOnEntities < ActiveRecord::Migration[8.0]
  def change
    change_column_null :entities, :identifier, false
  end
end
