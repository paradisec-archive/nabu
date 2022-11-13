class CreateItems < ActiveRecord::Migration[4.2]
  def change
    create_table :items, charset: "latin1" do |t|
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
      t.belongs_to :item,   :null => false
      t.belongs_to :country,   :null => false
    end
    add_index :item_countries, [:item_id, :country_id], :unique => :true

    create_table :item_subject_languages do |t|
      t.belongs_to :item,   :null => false
      t.belongs_to :language,   :null => false
    end
    add_index :item_subject_languages, [:item_id, :language_id], :unique => :true

    create_table :item_content_languages do |t|
      t.belongs_to :item,   :null => false
      t.belongs_to :language,   :null => false
    end
    add_index :item_content_languages, [:item_id, :language_id], :unique => :true

    create_table :item_admins do |t|
      t.belongs_to :item,   :null => false
      t.belongs_to :user,   :null => false
    end
    add_index :item_admins, [:item_id, :user_id], :unique => :true

    create_table :item_agents do |t|
      t.belongs_to :item,   :null => false
      t.belongs_to :user,   :null => false
      t.belongs_to :agent_role,   :null => false
    end
    add_index :item_agents, [:item_id, :user_id, :agent_role_id], :unique => :true

    create_table :agent_roles do |t|
      t.string :name, :null => false
    end

    create_table :discourse_types, charset: "latin1" do |t|
      t.string :name,   :null => false
    end
    add_index :discourse_types, :name, :unique => true
  end
end
