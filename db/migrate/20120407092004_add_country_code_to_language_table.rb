class AddCountryCodeToLanguageTable < ActiveRecord::Migration
  def change
    change_table :languages do |t|
      t.belongs_to :country, :null => false
    end
    add_index :languages, [:country_id]
  end
end
