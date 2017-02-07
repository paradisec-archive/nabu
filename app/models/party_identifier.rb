class PartyIdentifier < ActiveRecord::Base
  TYPES = [:NLA, :ORCID]

  belongs_to :user

  attr_accessible :user_id, :party_type, :identifier
  attr_accessible :user_id, :party_type, :identifier, as: :admin

  validates_presence_of :user_id, :party_type
  validates_uniqueness_of :party_type, scope: :user_id
end
