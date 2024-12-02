class AddCountryTable < ActiveRecord::Migration[4.2]
  def change
    create_table :countries, charset: "latin1" do |t|
      t.string :code
      t.string :name
    end
    add_index :countries, :name, unique: true
    add_index :countries, :code, unique: true

    create_table :collection_countries do |t|
      t.belongs_to :collection
      t.belongs_to :country
    end
    add_index :collection_countries, [:collection_id, :country_id], unique: :true
  end
end
