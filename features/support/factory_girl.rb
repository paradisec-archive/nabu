
require 'factory_girl'

FactoryGirl.define do
  factory :user, :aliases => [:collector] do
    sequence(:email) {|n| "john#{n}@robotparade.com.au"}
    first_name 'John'
    last_name  'Ferlito'
    password 'password'
    password_confirmation { password }
    confirmed_at Time.now

    factory :admin_user do
      admin true
    end
  end

  factory :university do
    sequence(:name) {|n| "University of Awesome #{n}"}
  end

  factory :country do
    sequence(:name) {|n| "Country #{n}"}
  end

  factory :language do
    sequence(:code) {|n| "sk#{n}"}
    sequence(:name) {|n| "University of Awesome #{n}"}
  end

  factory :field_of_research do
    sequence(:identifier) {|n| n}
    sequence(:name) {|n| "Moo #{n}"}
  end

  factory :collection do
    sequence(:identifier) {|n| "AA#{n}"}
    title 'Collection Title'
    description 'The awesome collection'
    region 'East Africa'
    latitude 40.6
    longitude -60.7
    zoom 5
    field_of_research
    university
    collector
  end
end
