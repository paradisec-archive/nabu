class ChangeFundingBodyToMultiple < ActiveRecord::Migration
  def up
    create_table :collections_funding_bodies, :id => false do |t|
      t.references :collection, :null => false
      t.references :funding_body, :null => false
    end
    add_index :collections_funding_bodies, [:collection_id, :funding_body_id], name: :lookup_by_collection_and_funding_body_index

    Collection.class_eval do
      belongs_to :old_funding_body, class_name: 'FundingBody', foreign_key: 'funding_body_id'
    end

    Collection.all.each do | coll |
      unless coll.old_funding_body.nil?
        coll.funding_bodies << coll.old_funding_body
        coll.save
      end
    end

    remove_column :collections, :funding_body_id
  end

  def down
    add_column :collections, :funding_body_id, :integer

    Collection.class_eval do
      belongs_to :new_funding_body, class_name: 'FundingBody', foreign_key: 'funding_body_id'
    end

    Collection.all.each do | coll |
      # Note: this will drop all but the first funding body, if multiple are present
      unless coll.funding_bodies.empty?
        coll.new_funding_body = coll.funding_bodies.first
        coll.save
      end
    end

    drop_table :collections_funding_bodies
  end
end
