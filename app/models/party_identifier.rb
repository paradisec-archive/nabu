class PartyIdentifier < ActiveRecord::Base
  TYPES = [:NLA, :ORCID]

  belongs_to :user

  validates_presence_of :user_id, :party_type
  validates_uniqueness_of :party_type, scope: :user_id
end
