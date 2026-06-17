FactoryBot.define do
  factory :user, aliases: [:collector, :operator] do
    sequence(:email) { |n| "john#{n}@robotparade.com.au" }
    first_name { 'John' }
    last_name  { 'Ferlito' }
    password { 'password' }
    password_confirmation { password }
    confirmed_at { Time.now }
    terms_accepted_at { Time.current }

    factory :admin_user do
      admin { true }
    end

    trait :contact_only do
      contact_only { true }
      email { nil }
      confirmed_at { nil }
    end
  end
end
