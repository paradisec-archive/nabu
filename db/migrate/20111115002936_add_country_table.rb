class AddCountryTable < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.string :name
    end
    add_index :countries, :name, :unique => true

    create_table :collection_countries do |t|
      t.belongs_to :collection
      t.belongs_to :country
    end
    add_index :collection_countries, [:collection_id, :country_id], :unique => :true
  end
end
