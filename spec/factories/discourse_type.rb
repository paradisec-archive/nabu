FactoryBot.define do
  factory :discourse_type do
    sequence(:name) {|n| "Discourse Type #{n}"}
  end
end
