FactoryBot.define do
  factory :access_condition do
    sequence(:name) { |n| "Open / Closed / Mixed #{n}" }
  end
end
