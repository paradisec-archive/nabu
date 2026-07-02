require 'rails_helper'

describe CollectionsController, type: :controller do
  let(:manager) { create(:user, admin: true) }
  let(:editor) { create(:user) }
  let(:grantee) { create(:user) }
  let(:evil) { create(:user) }

  let(:collection) do
    create(
      :collection,
      admins: [editor],
      users: [grantee]
    )
  end

  def update_collection
    patch :update, params: {
      id: collection.identifier,
      collection: { title: 'Updated title', admin_ids: [evil.id.to_s], user_ids: [''] }
    }
  end

  context 'when assigning grants via the collection form' do
    before { request.env['devise.mapping'] = Devise.mappings[:user] }

    context 'when a non-admin editor submits the form' do
      before { sign_in(editor, scope: :user) }

      it 'saves metadata changes but leaves grants untouched' do
        update_collection
        collection.reload
        expect(collection.title).to eq('Updated title')
        expect(collection.admins).to contain_exactly(editor)
        expect(collection.users).to contain_exactly(grantee)
      end
    end

    context 'when an admin submits the form' do
      before { sign_in(manager, scope: :user) }

      it 'applies the grant changes' do
        update_collection
        collection.reload
        expect(collection.admins).to contain_exactly(evil)
        expect(collection.users).to be_empty
      end
    end
  end

  # Regression for NABU-QA: a spreadsheet row whose title exceeds the column length used to make
  # item.save! raise ActiveRecord::ValueTooLong and 500 the whole upload. The bad row should now be
  # reported back to the uploader while the good rows still save.
  describe 'POST #create_from_spreadsheet with an over-long item title', :no_catalog_upload do
    let(:sheet_collection) { build(:collection) }
    let(:bad_item) { build(:item, collection: sheet_collection, title: 'a' * 256) }
    let(:upload) { Rack::Test::UploadedFile.new('spec/support/data/minimal_metadata/470 PDSC_minimal_metadataxls.xls') }

    before do
      request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in(manager, scope: :user)

      sheet = instance_double(
        Nabu::Spreadsheet,
        parse: nil, valid?: true, collection: sheet_collection, items: [bad_item], notices: [], errors: []
      )
      allow(Nabu::Spreadsheet).to receive(:new_of_correct_type).and_return(sheet)
    end

    it 'saves the collection, skips the bad row and reports it instead of 500ing' do
      post :create_from_spreadsheet, params: { collection: { metadata: upload } }

      aggregate_failures do
        expect(response).to redirect_to(sheet_collection)
        expect(sheet_collection).to be_persisted
        expect(bad_item).not_to be_persisted
        expect(flash[:error]).to include('Some items could not be saved')
        expect(flash[:error]).to include(bad_item.identifier)
      end
    end
  end
end
