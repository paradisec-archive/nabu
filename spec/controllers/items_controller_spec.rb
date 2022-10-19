require 'spec_helper'

describe ItemsController, type: :controller do
  let(:user) {create(:user)}
  let(:manager) {create(:user, admin: true)}

  let(:languages) {create_list(:language, 2)}
  let(:subject_languages) {create_list(:language, 2)}
  let(:collection) {create(:collection, languages: languages)}
  let(:item) {create(:item, collection: collection,
                     access_condition: AccessCondition.new({name: 'Open (subject to agreeing to PDSC access conditions)'}),
                     subject_languages: subject_languages)}
  let(:private_item) {create(:item, collection: collection, private: true)}
  let(:essence) {create(:sound_essence)}
  let(:item_with_essences) {create(:item, collection: collection, essences: [essence])}

  let(:params) { {collection_id: collection.identifier, id: item.identifier} }

  before(:all) do
    # allow test user to access everything
    item.item_users << ItemUser.new({item: item, user: user})
  end

  context 'when not logged in' do
    context 'when viewing' do
      context 'a private item' do
        it 'should redirect to the sign in page with error' do
          get :show, params.merge(id: private_item.identifier)
          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:alert]).to_not be_nil
        end
      end
      context 'a public item' do
        it 'should proceed' do
          get :show, params
          expect(response).to render_template(:show)
        end
      end
    end
  end

  context 'when logged in' do
    before do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      # log in as test user
      sign_in :user, user
    end
    context 'when viewing' do
      context 'a private item' do
        it 'should proceed' do
          get :show, params
          expect(response).to render_template(:show)
        end
      end
      context 'a public item' do
        it 'should proceed' do
          get :show, params
          expect(response).to render_template(:show)
        end
      end
    end

    context 'when creating an item' do
      it 'should attempt to create the archive directory' do
        #expect the interaction but don't try to create anything
        # FIXME: JF commit 36d9b0efd1d964187f51f9f3e9038f765cad272d removed this, is it needed?
        # controller.should_receive(:save_item_catalog_file).and_return(nil)
        post :create, {collection_id: collection.identifier, item: {collector_id: user.id, identifier: '321', title: 'title goes here'}}
        expect(response).to redirect_to(params.merge(id: '321', action: :show))
        expect(flash[:notice]).to_not be_nil
      end
      context 'that is invalid' do
        it 'should fail and show create page' do
          post :create, {collection_id: collection.identifier, item: {title: 'title goes here'}}
          expect(response).to render_template(:new)
        end
      end
    end

    context 'when destroying an item' do
      context 'with a non-admin user' do
        it 'should fail and redirect with error' do
          delete :destroy, params
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to_not be_nil
        end
      end
      context 'with an admin user' do
        before do
          ItemDestructionService.stub(:destroy).and_return({success: true, messages: {notice: 'yay'}})

          @request.env['devise.mapping'] = Devise.mappings[:user]
          # log in as test user
          sign_in :user, manager
        end
        context 'with no essences' do
          it 'should proceed' do
            delete :destroy, params
            expect(response).to redirect_to(collection)
            expect(flash[:notice]).to eq('yay')
          end
        end
        context 'with essences' do
          context 'and flag set to true' do
            it 'should proceed' do
              delete :destroy, params
              expect(response).to redirect_to(collection)
              expect(flash[:notice]).to eq('yay')
            end
          end
          context 'and flag set to false' do
            before do
              ItemDestructionService.stub(:destroy).and_return({success: false, messages: {error: 'boo'}})
            end
            it 'should fail and redirect with error' do
              delete :destroy, params
              expect(response).to redirect_to([collection, item])
              expect(flash[:error]).to eq('boo')
            end
          end
        end
      end
    end

    context 'when inheriting from collection' do
      before do
        @request.env['devise.mapping'] = Devise.mappings[:user]
        # log in as test user
        sign_in :user, manager
      end
      it 'should not override existing values by default' do
        pending 'INVESTIGATE 2016-04-21: Sometimes but not always failing on development machines'
        put :inherit_details, params
        expect(response).to redirect_to([collection, item])
        expect(flash[:notice]).to_not be_nil
        result_item = Item.find(item.id)
        expect(result_item.subject_languages.sort).to eq(item.subject_languages.sort)
        expect(result_item.subject_languages.sort).to_not eq(collection.languages.sort)
      end

      it 'should override values if flag is set to true' do
        put :inherit_details, params.merge(override_existing: true)
        expect(response).to redirect_to([collection, item])
        expect(flash[:notice]).to_not be_nil
        result_item = Item.find(item.id)
        expect(result_item.subject_languages.sort).to_not eq(item.subject_languages.sort)
        expect(result_item.subject_languages.sort).to eq(collection.languages.sort)
      end

      context 'when an error occurs' do
        it 'should fail and redirect with error' do
          Item.any_instance.stub(:inherit_details_from_collection).and_return(false)
          put :inherit_details, params
          expect(response).to redirect_to([collection, item])
          expect(flash[:alert]).to_not be_nil
        end
      end
    end
  end

  context 'when viewing an item with essences' do
    it 'should track the essence files' do
      get :show, params.merge(id: item_with_essences.identifier)
      expect(assigns(:num_files)).to eq(1)
      expect(assigns(:files)).to eq([essence])
    end
  end
  context 'when viewing an item as xml' do
    context 'with a specific type' do
      it 'should render the specific template' do
        get :show, params.merge(format: :xml, xml_type: :id3)
        expect(response).to render_template(file: 'items/show.id3.xml')
      end
    end
    context 'with no type' do
      it 'should render the default template' do
        get :show, params.merge(format: :xml)
        expect(response).to render_template(file: 'items/show.xml')
      end
    end
  end
end
