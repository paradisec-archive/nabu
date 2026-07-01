require 'rails_helper'

describe ItemAnnotationsController, type: :controller do
  let(:user) { create(:user) }
  let(:collection) { create(:collection) }
  let(:item) { create(:item, collection: collection) }
  let(:eaf) { create(:essence, item: item, filename: 'sample.eaf', mimetype: 'text/xml', size: 100) }
  let(:mp3) { create(:essence, item: item, filename: 'sample.mp3', mimetype: 'audio/mp3', size: 100) }
  let(:wav) { create(:essence, item: item, filename: 'other.wav', mimetype: 'audio/wav', size: 100) }

  let(:base_params) { { collection_id: collection.identifier, item_id: item.identifier } }

  before { item.admins << user }

  context 'when not logged in' do
    it 'redirects from show' do
      get :show, params: base_params
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'when logged in as an item admin' do
    before { sign_in(user, scope: :user) }

    describe 'GET show' do
      it 'renders successfully' do
        eaf
        mp3
        get :show, params: base_params
        expect(response).to have_http_status(:ok)
        expect(assigns(:transcripts)).to include(eaf)
        expect(assigns(:media)).to include(mp3)
      end
    end

    describe 'PATCH update' do
      it 'creates a new mapping when requested' do
        eaf
        mp3
        expect {
          patch :update, params: base_params.merge(mappings: { eaf.id.to_s => [mp3.id.to_s] })
        }.to change(EssenceAnnotation, :count).by(1)
        expect(eaf.reload.annotates).to include(mp3)
      end

      it 'removes a mapping when the box is unticked' do
        EssenceAnnotation.create!(annotation_essence: eaf, target_essence: mp3)
        expect {
          patch :update, params: base_params.merge(mappings: { eaf.id.to_s => [''] })
        }.to change(EssenceAnnotation, :count).by(-1)
      end

      it 'reconciles diffs in a single submit (adds one, removes another)' do
        EssenceAnnotation.create!(annotation_essence: eaf, target_essence: mp3)
        patch :update, params: base_params.merge(mappings: { eaf.id.to_s => [wav.id.to_s] })
        expect(eaf.reload.annotates).to contain_exactly(wav)
      end
    end
  end

  context 'when logged in as an unrelated user' do
    let(:other_user) { create(:user) }
    before { sign_in(other_user, scope: :user) }

    it 'denies access' do
      get :show, params: base_params
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be_present
    end
  end
end
