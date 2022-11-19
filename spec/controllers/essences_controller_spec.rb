require 'rails_helper'

describe EssencesController, type: :controller do
  let(:user) {create(:user)}
  let(:manager) {create(:user, admin: true)}

  let(:collection) {create(:collection)}
  let(:access_condition) { AccessCondition.new({name: 'Open (subject to agreeing to PDSC access conditions)'}) }
  let(:item) {create(:item, collection: collection, access_condition: access_condition)}
  let(:essence) {create(:sound_essence, item: item)}

  let(:params) { {collection_id: collection.identifier, item_id: item.identifier, id: essence.id} }

  before(:each) do
    # allow test user to access everything
    item.item_users << ItemUser.new({item: item, user: user})
  end

  context 'when not logged in' do
    context 'when viewing an essence' do
      it 'should redirect to the sign in page with error' do
        get :show, params: params
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to_not be_nil
      end
    end
  end

  context 'when logged in' do
    before do
      sign_in(user, scope: :user)
    end
    context 'when viewing an essence' do
      context 'when not agreed to terms' do
        it 'should redirect to show terms page' do
          session.delete("terms_#{collection.id}")

          get :show, params: params
          expect(response).to redirect_to(params.merge(action: :show_terms))
        end
      end

      context 'when agreed to terms' do
        it 'should load the essence' do
          # test user has already agreed to terms
          session["terms_#{collection.id}"] = true

          get :show, params: params
          expect(response.status).to eq(200)
          expect(response).to render_template(:show)
        end
      end
      context 'as an admin' do
        before do
          # log in as test user
          sign_in(manager, scope: :user)
        end
        it 'should load the essence without agreeing to terms' do
          # admin doesn't need to agree
          session["terms_#{collection.id}"] = false

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
          expect(session).to_not have_key("terms_#{collection.id}")
          expect(response).to redirect_to(params.reject{|x,y| x == :item_id}.merge(id: item.identifier, controller: :items, action: :show))
          expect(flash[:error]).to eq 'Item does not have data access conditions set'
        end
      end
    end

    context 'when shown terms' do
      before do
        #clear session
        session.delete("terms_#{collection.id}")
      end
      context 'when agreeing to terms' do
        it 'should redirect to show essence page' do
          get :agree_to_terms, params: params.merge(agree: 1)
          expect(session).to have_key("terms_#{collection.id}")
          expect(session["terms_#{collection.id}"]).to eq(true)
          expect(response).to redirect_to(params.merge(action: :show))
          expect(flash[:error]).to be_nil
        end
      end

      context 'when not agreeing to terms' do
        it 'should redirect to show item page with error' do
          get :agree_to_terms, params: params
          expect(session).to_not have_key("terms_#{collection.id}")
          expect(response).to redirect_to(params.reject{|x,y| x == :item_id}.merge(id: item.identifier, controller: :items, action: :show))
          expect(flash[:error]).to_not be_nil
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
