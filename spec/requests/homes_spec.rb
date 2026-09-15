require 'rails_helper'

describe 'home page', type: :request do
  let(:user) { create(:user) }

  it 'redirects to the login page when not signed in' do
    get root_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it 'shows the dashboard when signed in' do
    sign_in user
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to have_text("Dashboard for #{user.name}")
  end
end
