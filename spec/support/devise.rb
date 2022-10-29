module DeviseFeatureMacros
  def login(user)
    visit new_user_session_path
    fill_in 'Email', :with => user.email
    fill_in 'Password', :with => 'password'
    click_button 'Sign in'
  end
end

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view

  config.include DeviseFeatureMacros #, :type => :feature

  include Warden::Test::Helpers
  Warden.test_mode!
end
