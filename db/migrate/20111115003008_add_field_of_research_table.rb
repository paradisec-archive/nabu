class AddFieldOfResearchTable < ActiveRecord::Migration
 def change
    create_table :fields_of_research do |t|
      t.string :identifier
      t.string :name
    end
    add_index :fields_of_research, :name, :unique => true
    add_index :fields_of_research, :identifier, :unique => true

    create_table :collection_fields_of_research do |t|
      t.belongs_to :collection
      t.belongs_to :field_of_research
    end
    add_index :collection_fields_of_research, [:collection_id, :field_of_research_id], :unique => :true, :name => 'collection_fields_of_research_idx'
  end
end
