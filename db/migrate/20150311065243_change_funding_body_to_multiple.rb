class ChangeFundingBodyToMultiple < ActiveRecord::Migration[4.2]
  def up
    Collection.class_eval do
      belongs_to :old_funding_body, class_name: 'FundingBody', foreign_key: 'funding_body_id'
    end

    Collection.all.each do | coll |
      unless coll.old_funding_body.nil?
        coll.grants << Grant.new({ collection_id: coll.id, funding_body_id: coll.old_funding_body.id, grant_identifier: coll.grant_identifier })
        coll.save
      end
    end

    remove_column :collections, :funding_body_id
    remove_column :collections, :grant_identifier
  end

  def down
    add_column :collections, :funding_body_id, :integer
    add_column :collections, :grant_identifier, :string

    Collection.class_eval do
      belongs_to :new_funding_body, class_name: 'FundingBody', foreign_key: 'funding_body_id'
    end

    Collection.all.each do | coll |
      # Note: this will drop all but the first funding body, if multiple are present
      unless coll.grants.empty?
        coll.new_funding_body = coll.grants.first.funding_body
        coll.grant_identifier = coll.grants.first.grant_identifier
        coll.save
      end
    end
  end
end
