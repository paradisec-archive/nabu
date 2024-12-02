class AddPartyIdentifiers < ActiveRecord::Migration[4.2]
  def change
    change_table :users do |t|
      t.string :party_identifier
    end

    change_table :universities do |t|
      t.string :party_identifier
    end
  end
end
