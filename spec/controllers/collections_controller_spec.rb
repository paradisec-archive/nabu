require 'rails_helper'

describe CollectionsController, type: :controller do
  let(:manager) { create(:user, admin: true) }
  let(:editor) { create(:user) }
  let(:grantee) { create(:user) }
  let(:evil) { create(:user) }

  let(:collection) do
    create(
      :collection,
      collection_admins: [CollectionAdmin.new(user: editor)],
      collection_users: [CollectionUser.new(user: grantee)]
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
end
