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
end
