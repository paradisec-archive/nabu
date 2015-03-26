class RemoveRedundantFundingBodyLookupTable < ActiveRecord::Migration
  def up
    Collection.class_eval do
      has_and_belongs_to_many :old_funding_bodies, class_name: 'FundingBody'
    end

    Collection.all.each do |coll|
      coll.old_funding_bodies.each do |fb|
        coll.grants << Grant.new({collection_id: coll.id, funding_body_id: fb.id, grant_identifier: coll.grant_identifier})
      end

      if coll.changed?
        coll.save!
      end
    end
    drop_table :collections_funding_bodies
  end
end
