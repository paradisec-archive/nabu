Given /^I am signed in as #{capture_model}$/ do |user|
  @user = model!(user)

  step 'I go to the homepage'
  step 'I follow "Sign in"'
  step "I fill in \"Email\" with \"#{@user.email}\""
  step "I fill in \"Password\" with \"#{Factory.attributes_for(:user)[:password]}\""
  step 'I press "Sign in"'
end

Given /^I am signed out$/ do
  if page.has_content?('Sign out')
    step 'I follow "Sign out"'
  end
end

