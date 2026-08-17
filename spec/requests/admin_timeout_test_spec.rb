require 'rails_helper'

describe 'Admin timeout test', type: :request do
  context 'as an admin' do
    before { sign_in create(:user, admin: true) }

    it 'renders the test page' do
      get '/admin/timeout_test'

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('/admin/timeout_test/sleep')
    end

    it 'sleeps for the requested duration before responding' do
      get '/admin/timeout_test/sleep', params: { seconds: 0.2 }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['actual']).to be >= 0.2
    end

    it 'caps the sleep so a stray request cannot pin a thread indefinitely' do
      expect(Kernel).to receive(:sleep).with(600)

      get '/admin/timeout_test/sleep', params: { seconds: 10_000 }

      expect(response.parsed_body['requested']).to eq(600)
    end
  end

  it 'is not reachable by non-admins' do
    sign_in create(:user, admin: false)
    get '/admin/timeout_test'

    expect(response).to redirect_to(new_user_session_path)
  end
end
