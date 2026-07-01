require 'rails_helper'

describe 'home page' do
  let(:user) { create(:user) }

  it 'redirects to the login page when not signed in' do
    visit root_path
    expect(page).to have_current_path(new_user_session_path)
  end

  it 'shows the dashboard when signed in' do
    login_as user, scope: :user
    visit root_path
    expect(page.status_code).to be(200)
    expect(page).to have_text("Dashboard for #{user.name}")
  end
end
