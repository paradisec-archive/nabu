FactoryBot.define do
  factory :field_of_research do
    sequence(:identifier) { |n| n }
    sequence(:name) { |n| "East African Studies #{n}" }
  end
end
