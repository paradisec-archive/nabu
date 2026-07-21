require 'rails_helper'

describe EssencesController, type: :controller do
  let(:user) { create(:user) }
  let(:manager) { create(:user, admin: true) }

  let(:collection) { create(:collection) }
  let(:access_condition) { AccessCondition.new({ name: 'Open (subject to agreeing to PDSC access conditions)' }) }
  let(:item) { create(:item, collection: collection, access_condition: access_condition) }
  let(:essence) { create(:sound_essence, item: item) }
  let(:ingest_notes) { "processS3Event: moo.wav added\nSet volume to -3dB" }

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
        expect(flash[:alert]).not_to be_nil
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

        context 'when the essence has flat extracted text' do
          render_views

          let(:essence) { create(:sound_essence, item: item, extracted_content: 'Some extracted words', extracted_content_type: 'text') }

          it 'shows the extracted text' do
            get :show, params: params
            expect(response.body).to include('Extracted Text')
            expect(response.body).to include('Some extracted words')
          end
        end

        context 'when the essence has PDF page segments' do
          render_views

          let(:segments) do
            [
              { type: 'page', page: 1, text: 'First page words' },
              { type: 'page', page: 2, text: 'Second page words' }
            ]
          end
          let(:essence) { create(:sound_essence, item: item, extracted_content: segments.to_json, extracted_content_type: 'pdf') }

          it 'shows a segment preview with page labels' do
            get :show, params: params
            expect(response.body).to include('2 segments indexed for search')
            expect(response.body).to include('Page 1: First page words')
          end
        end

        context 'when the essence has ELAN annotation segments' do
          render_views

          let(:segments) { [{ type: 'time-aligned-annotation', tier: 'transcript', start_ms: 1500, end_ms: 3000, text: 'Spoken words' }] }
          let(:essence) { create(:sound_essence, item: item, extracted_content: segments.to_json, extracted_content_type: 'elan') }

          it 'shows a segment preview with tier and timecode labels' do
            get :show, params: params
            expect(response.body).to include('1 segment indexed for search')
            expect(response.body).to include('transcript [00:00:01.500 - 00:00:03.0]: Spoken words')
          end
        end

        context 'when the essence has ingest notes' do
          render_views

          let(:essence) { create(:sound_essence, item: item, ingest_notes: ingest_notes) }

          it 'shows the ingest notes' do
            get :show, params: params
            expect(response.body).to include('Ingest Notes')
            expect(response.body).to include('Set volume to -3dB')
          end
        end
      end

      context 'as a non-admin when the essence has ingest notes' do
        render_views

        let(:essence) { create(:sound_essence, item: item, ingest_notes: "processS3Event: moo.wav added\nSet volume to -3dB") }

        it 'does not show the ingest notes' do
          get :show, params: params
          expect(response.status).to eq(200)
          expect(response.body).not_to include('Ingest Notes')
          expect(response.body).not_to include('Set volume to -3dB')
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
