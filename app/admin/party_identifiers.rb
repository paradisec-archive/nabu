ActiveAdmin.register PartyIdentifier do
  menu :parent => "Other Entities"
  config.sort_order = "identifier_asc"
  actions :all

  permit_params :user_id, :party_type, :identifier

  filter :user
  filter :party_type
  filter :identifier
end
