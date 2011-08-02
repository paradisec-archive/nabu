
require 'factory_girl'

FactoryGirl.define do
  factory :user do
    sequence(:email) {|n| "john#{n}@robotparade.com.au"}
    first_name 'John'
    last_name  'Ferlito'
    password 'really_secret'
    password_confirmation { password }
    confirmed_at Time.now
  end
end
