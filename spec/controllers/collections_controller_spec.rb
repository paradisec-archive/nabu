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

  # Regression for NABU-KW/QG: can?(:read, item) in the show view re-queried the polymorphic
  # `permissions` table once per item because collection_grant_permissions was not preloaded, so
  # the permission query count scaled with the number of items on the page. It must now be constant.
  describe 'GET #show permission preloading', :no_catalog_upload do
    render_views

    before do
      request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in(editor, scope: :user)
    end

    def permission_queries_for(item_count)
      create_list(:item, item_count, collection:)
      queries = 0
      counter = lambda do |_name, _start, _finish, _id, payload|
        queries += 1 if payload[:sql] =~ /\bpermissions\b/i && payload[:name] != 'SCHEMA'
      end
      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
        get :show, params: { id: collection.identifier }
      end
      queries
    end

    it 'does not issue more permission queries as the number of items grows' do
      one_item = permission_queries_for(1)
      Item.where(collection:).destroy_all
      many_items = permission_queries_for(5)

      expect(many_items).to eq(one_item)
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
