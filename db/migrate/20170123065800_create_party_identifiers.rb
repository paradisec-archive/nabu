class CreatePartyIdentifiers < ActiveRecord::Migration[4.2]
  def change
    create_table :party_identifiers do |t|
      t.references :user, null: false, index: true
      t.integer :party_type, null: false, index: true
      t.string :identifier, null: false
      t.timestamps
    end
  end
end
