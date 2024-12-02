class AddCountryCodeToLanguageTable < ActiveRecord::Migration[4.2]
  def change
    change_table :languages, charset: "latin1" do |t|
      t.belongs_to :country, null: false
    end
    add_index :languages, [:country_id]
  end
end
