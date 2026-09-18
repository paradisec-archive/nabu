FactoryBot.define do
  factory :language_equivalent do
    language
    related_language factory: %i[language glottolog]
    evidence { ['glottolog:iso'] }
  end
end
