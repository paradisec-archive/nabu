class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.belongs_to :collection,  :null => false
      t.string     :identifier,  :null => false
      t.boolean    :private
      t.string     :title,       :null => false
      t.string     :url
      t.belongs_to :collector,   :null => false
      t.belongs_to :university
      t.belongs_to :operator
      t.text       :description, :null => false
      t.date       :originated_on
      t.string     :language
      t.belongs_to :subject_language
      t.belongs_to :content_language
      t.string     :dialect
      t.string     :region
      t.float      :latitude
      t.float      :longitude
      t.integer    :zoom
      t.belongs_to :discourse_type

      t.belongs_to :access_condition
      t.text :access_narrative

      t.timestamps
    end

    add_index :items, [:identifier, :collection_id], :unique => true
    add_index :items, :collection_id

    create_table :item_countries do |t|
      t.belongs_to :item
      t.belongs_to :country
    end
    add_index :item_countries, [:item_id, :country_id], :unique => :true

    create_table :item_admins do |t|
      t.belongs_to :item
      t.belongs_to :user
    end
    add_index :item_admins, [:item_id, :user_id], :unique => :true

    create_table :item_agents do |t|
      t.belongs_to :item
      t.belongs_to :user
      t.belongs_to :agent_role
    end
    add_index :item_agents, [:item_id, :user_id, :agent_role_id], :unique => :true

    create_table :agent_roles do |t|
      t.string :name, :null => false
    end

    create_table :discourse_types do |t|
      t.string :name
    end
    add_index :discourse_types, :name, :unique => true
  end
end
