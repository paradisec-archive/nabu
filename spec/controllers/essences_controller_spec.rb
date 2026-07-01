require 'rails_helper'

describe EssencesController, type: :controller do
  let(:user) { create(:user) }
  let(:manager) { create(:user, admin: true) }

  let(:collection) { create(:collection) }
  let(:access_condition) { AccessCondition.new({ name: 'Open (subject to agreeing to PDSC access conditions)' }) }
  let(:item) { create(:item, collection: collection, access_condition: access_condition) }
  let(:essence) { create(:sound_essence, item: item) }

  let(:params) { { collection_id: collection.identifier, item_id: item.identifier, id: essence.id } }

  before do
    # allow test user to access everything
    item.users << user
  end

  context 'when not logged in' do
    context 'when viewing an essence' do
      it 'redirects to the sign in page with error' do
        get :show, params: params
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:notice]).not_to be_nil
      end
    end
  end

  context 'when logged in' do
    before do
      sign_in(user, scope: :user)
    end

    context 'when viewing an essence' do
      it 'loads the essence' do
        get :show, params: params
        expect(response.status).to eq(200)
        expect(response).to render_template(:show)
      end

      context 'as an admin' do
        before do
          sign_in(manager, scope: :user)
        end

        it 'loads the essence' do
          get :show, params: params
          expect(response.status).to eq(200)
          expect(response).to render_template(:show)
          expect(flash[:error]).to be_nil
        end
      end

      context 'when access_condition_id nil' do
        let(:access_condition) { nil }

        it 'redirects to show item page with error' do
          get :show, params: params
          expect(response).to redirect_to(params.reject { |x, _y| x == :item_id }.merge(id: item.identifier, controller: :items, action: :show))
          expect(flash[:error]).to eq 'Item does not have data access conditions set'
        end
      end
    end
  end
end
