class AddIdentifierToEntities < ActiveRecord::Migration[8.0]
  def change
    add_column :entities, :identifier, :string
    add_index :entities, :identifier
  end
end
