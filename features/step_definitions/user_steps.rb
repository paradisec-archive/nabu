Given /^I am signed in as #{capture_model}$/ do |user|
  @user = model!(user)

  Given 'I go to the homepage'
  And 'I follow "Sign in"'
  And "I fill in \"Email\" with \"#{@user.email}\""
  And "I fill in \"Password\" with \"#{Factory.attributes_for(:user)[:password]}\""
  And 'I press "Sign in"'
end

Given /^I am signed out$/ do
  Given 'I follow "Sign out"'
end

