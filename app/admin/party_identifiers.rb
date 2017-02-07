ActiveAdmin.register PartyIdentifier do
  menu :parent => "Other Entities"
  config.sort_order = "identifier_asc"
  actions :all

  filter :user
  filter :party_type
  filter :identifier
end
