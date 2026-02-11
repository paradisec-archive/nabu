require 'rails_helper'

describe EssencesController, type: :controller do
  let(:user) { create(:user) }
  let(:manager) { create(:user, admin: true) }

  let(:collection) { create(:collection) }
  let(:access_condition) { AccessCondition.new({ name: 'Open (subject to agreeing to PDSC access conditions)' }) }
  let(:item) { create(:item, collection: collection, access_condition: access_condition) }
  let(:essence) { create(:sound_essence, item: item) }

  let(:params) { { collection_id: collection.identifier, item_id: item.identifier, id: essence.id } }

  before(:each) do
    # allow test user to access everything
    item.item_users << ItemUser.new({ item: item, user: user })
  end

  context 'when not logged in' do
    context 'when viewing an essence' do
      it 'should redirect to the sign in page with error' do
        get :show, params: params
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:notice]).to_not be_nil
      end
    end
  end

  context 'when logged in' do
    before do
      sign_in(user, scope: :user)
    end

    context 'when viewing an essence' do
      it 'should load the essence' do
        get :show, params: params
        expect(response.status).to eq(200)
        expect(response).to render_template(:show)
      end

      context 'as an admin' do
        before do
          sign_in(manager, scope: :user)
        end
        it 'should load the essence' do
          get :show, params: params
          expect(response.status).to eq(200)
          expect(response).to render_template(:show)
          expect(flash[:error]).to be_nil
        end
      end

      context 'when access_condition_id nil' do
        let(:access_condition) { nil }

        it 'should redirect to show item page with error' do
          get :show, params: params
          expect(response).to redirect_to(params.reject { |x, _y| x == :item_id }.merge(id: item.identifier, controller: :items, action: :show))
          expect(flash[:error]).to eq 'Item does not have data access conditions set'
        end
      end
    end

    context 'when downloading a file' do
      # FIXME: JF bring this back later - issue with stubbing
      # it 'should make a record' do
      #   controller.stub!(:render)
      #   File.stub(:exist?) { true }
      #   expect(controller).to receive(:send_file)
      #
      #   expect{ get :download, params }.to change{ Download.count }.by(1)
      #   expect(Download.last.user).to eq(user)
      #   expect(Download.last.essence).to eq(essence)
      # end
    end
  end
end
