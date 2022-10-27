FactoryBot.define do
  factory :agent_role do
    sequence(:name) {|n| "author #{n}"}
  end
end
