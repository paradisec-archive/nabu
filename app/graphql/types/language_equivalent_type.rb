class Types::LanguageEquivalentType < Types::BaseObject
  description 'An advisory pairing with another language, and the evidence it rests on'

  field :evidence, [String], null: false
  field :language, Types::LanguageType, null: false
end
