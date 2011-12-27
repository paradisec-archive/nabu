
require 'factory_girl'

FactoryGirl.define do
  factory :user, :aliases => [:collector, :operator] do
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

  factory :discourse_type do
    sequence(:name) {|n| "Discourse Type #{n}"}
  end

  factory :language, :aliases => [:subject_language, :content_language] do
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

  factory :item do
    sequence(:identifier) {|n| "%03d" % n}
    title 'Title of item'
    description 'The awesome item'
    region 'East Africa'
    collector
    university
    operator
    latitude 40.6
    longitude -60.7
    zoom 5
    subject_language
    content_language
    discourse_type
    collection
    originated_on Time.now
  end

end
