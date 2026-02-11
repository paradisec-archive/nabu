require 'rails_helper'

RSpec.describe TermsController, type: :controller do
  let(:user) { create(:user, terms_accepted_at: nil) }
  let(:admin) { create(:user, admin: true, terms_accepted_at: nil) }

  describe 'GET #show' do
    context 'when not logged in' do
      it 'redirects to sign in' do
        get :show
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when logged in' do
      before { sign_in(user) }

      it 'renders the terms page' do
        get :show
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end
  end

  describe 'POST #accept' do
    context 'when not logged in' do
      it 'redirects to sign in' do
        post :accept, params: { agree: '1' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when logged in' do
      before { sign_in(user) }

      context 'when agreeing to terms' do
        it 'accepts terms and redirects to dashboard' do
          post :accept, params: { agree: '1' }
          expect(user.reload.terms_accepted_at).to be_present
          expect(response).to redirect_to(dashboard_path)
        end
      end

      context 'when not agreeing to terms' do
        it 'redirects back to terms with error' do
          post :accept
          expect(user.reload.terms_accepted_at).to be_nil
          expect(flash[:error]).to be_present
          expect(response).to redirect_to(terms_path)
        end
      end
    end
  end

  describe 'terms enforcement' do
    context 'when admin has not accepted terms' do
      before { sign_in(admin) }

      it 'is not redirected to terms page' do
        get :show
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user has expired terms' do
      let(:expired_user) { create(:user, terms_accepted_at: 4.months.ago) }

      before { sign_in(expired_user) }

      it 'renders the terms page' do
        get :show
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
      end
    end
  end
end
