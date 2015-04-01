FactoryGirl.define do
  factory :country do
    sequence(:code) {|n| "Code #{n}"}
    sequence(:name) {|n| "Country #{n}"}
  end
end
