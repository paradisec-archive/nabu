class AddFieldOfResearchTable < ActiveRecord::Migration[4.2]
 def change
    create_table :fields_of_research, charset: "latin1" do |t|
      t.string :identifier
      t.string :name
    end
    add_index :fields_of_research, :name, :unique => true
    add_index :fields_of_research, :identifier, :unique => true
  end
end
