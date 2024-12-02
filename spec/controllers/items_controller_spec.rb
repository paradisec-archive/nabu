require 'rails_helper'

describe ItemsController, type: :controller do
  let(:user) { create(:user) }
  let(:manager) { create(:user, admin: true) }

  let(:languages) { create_list(:language, 2) }
  let(:subject_languages) { create_list(:language, 2) }
  let(:collection) { create(:collection, languages: languages) }
  let(:item) { create(
    :item,
    collection: collection,
    access_condition: AccessCondition.new({ name: 'Open (subject to agreeing to PDSC access conditions)' }),
    subject_languages: subject_languages,
    item_users: [ItemUser.new({ user: user })]
  )}
  let(:private_item) { create(:item, collection: collection, private: true) }
  let(:essence) { create(:sound_essence) }
  let(:item_with_essences) { create(:item, collection: collection, essences: [essence]) }

  let(:params) { { collection_id: collection.identifier, id: item.identifier } }

  before(:all) do
    # allow test user to access everything
    # item.item_users << ItemUser.new({item: item, user: user})
  end

  context 'when not logged in' do
    context 'when viewing' do
      context 'a private item' do
        it 'should redirect to the sign in page with error' do
          get :show, params: params.merge(id: private_item.identifier)
          expect(response).to redirect_to(new_user_session_path)
          expect(flash[:alert]).to_not be_nil
        end
      end
      context 'a public item' do
        it 'should proceed' do
          get :show, params: params
          expect(response).to render_template(:show)
        end
      end
    end
  end

  context 'when logged in' do
    before do
      sign_in(user, scope: :user)
    end
    context 'when viewing' do
      context 'a private item' do
        it 'should proceed' do
          get :show, params: params
          expect(response).to render_template(:show)
        end
      end
      context 'a public item' do
        it 'should proceed' do
          get :show, params: params
          expect(response).to render_template(:show)
        end
      end
    end

    context 'when creating an item' do
      context 'that is invalid' do
        it 'should fail and show create page' do
          post :create, params: { collection_id: collection.identifier, item: { title: 'title goes here' } }
          expect(response).to render_template(:new)
        end
      end
    end

    context 'when destroying an item' do
      context 'with a non-admin user' do
        it 'should fail and redirect with error' do
          delete :destroy, params: params
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to_not be_nil
        end
      end
      context 'with an admin user' do
        before do
          allow(ItemDestructionService).to receive(:destroy).and_return({ success: true, messages: { notice: 'yay' } })

          @request.env['devise.mapping'] = Devise.mappings[:user]
          # log in as test user
          sign_in(manager, scope: :user)
        end
        context 'with no essences' do
          it 'should proceed' do
            delete :destroy, params: params
            expect(response).to redirect_to(collection)
            expect(flash[:notice]).to eq('yay')
          end
        end
        context 'with essences' do
          context 'and flag set to true' do
            it 'should proceed' do
              delete :destroy, params: params
              expect(response).to redirect_to(collection)
              expect(flash[:notice]).to eq('yay')
            end
          end
          context 'and flag set to false' do
            before do
              allow(ItemDestructionService).to receive(:destroy).and_return({ success: false, messages: { error: 'boo' } })
            end
            it 'should fail and redirect with error' do
              delete :destroy, params: params
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
        sign_in(manager, scope: :user)
      end
      it 'should not override existing values by default' do
        # pending 'INVESTIGATE 2016-04-21: Sometimes but not always failing on development machines'
        patch :inherit_details, params: params
        expect(response).to redirect_to([collection, item])
        expect(flash[:notice]).to_not be_nil
        result_item = Item.find(item.id)
        expect(result_item.subject_languages.sort).to eq(item.subject_languages.sort)
        expect(result_item.subject_languages.sort).to_not eq(collection.languages.sort)
      end

      it 'should override values if flag is set to true' do
        patch :inherit_details, params: params.merge(override_existing: true)
        expect(response).to redirect_to([collection, item])
        expect(flash[:notice]).to_not be_nil
        result_item = Item.find(item.id)
        expect(result_item.subject_languages.sort).to_not eq(item.subject_languages.sort)
        expect(result_item.subject_languages.sort).to eq(collection.languages.sort)
      end

      # FIXME: JF bring this back later - issue with stubbing
      # context 'when an error occurs', focus: true do
      #   it 'should fail and redirect with error' do
      #     Item.any_instance.stub(:inherit_details_from_collection).and_return(false)
      #     patch :inherit_details, params
      #     expect(response).to redirect_to([collection, item])
      #     expect(flash[:alert]).to_not be_nil
      #   end
      # end
    end
  end

  context 'when viewing an item with essences' do
    it 'should track the essence files' do
      get :show, params: params.merge(id: item_with_essences.identifier)
      # FIXME: JF assigns might not work see 5.0 guide 7.5
      expect(assigns(:num_files)).to eq(1)
      expect(assigns(:files)).to eq([essence])
    end
  end
end
