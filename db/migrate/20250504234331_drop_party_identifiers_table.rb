class DropPartyIdentifiersTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :party_identifiers
  end
end
