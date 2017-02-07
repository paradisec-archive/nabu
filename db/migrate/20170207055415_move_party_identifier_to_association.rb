class MovePartyIdentifierToAssociation < ActiveRecord::Migration
  def up
    existing_identifiers = User.select([:id, :party_identifier])
                               .reject{|a| a.party_identifier.nil?}
    existing_identifiers.each do |i|
      PartyIdentifier.create(user_id: i.id, identifier: i.party_identifier, party_type: PartyIdentifier::TYPES.index(:NLA))
    end
  end
end
