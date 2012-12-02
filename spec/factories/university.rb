FactoryGirl.define do
  factory :university do
    sequence(:name) {|n| "University of Awesome #{n}"}
  end
end
