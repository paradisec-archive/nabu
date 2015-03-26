class Grant < ActiveRecord::Base
  belongs_to :collection
  belongs_to :funding_body

  validates_uniqueness_of :grant_identifier, scope: [:collection_id, :funding_body_id], allow_blank: true, allow_nil: true

  scope :alpha, order('funding_body.name')

  attr_accessible :collection_id, :funding_body_id, :collection, :funding_body, :grant_identifier
end