require 'rails_helper'

# Regression coverage for the denormalised access_user_ids union in the search indexes.
# Collection, Item and Essence search documents each embed a single access_user_ids field holding
# the ids of everyone allowed to see them. When a grant is added or removed the affected documents
# must be reindexed, otherwise a revoked user keeps finding private records via search. The reindex
# is driven by Permission#reindex_search_documents.
describe 'Search visibility when access is granted and revoked', :search do
  let!(:user) { create(:user) }
  let!(:collection) { create(:collection, :reindex, identifier: 'PRIVCOLL', private: true) }
  let!(:item) { create(:item, :reindex, identifier: 'SECRETITEM', collection:, private: true) }

  before { login_as user, scope: :user }

  # Make whatever the reindex callbacks have already written visible to search, without
  # reindexing ourselves - that way the assertions exercise the callbacks, not the test setup.
  def refresh_search_indexes
    Collection.search_index.refresh
    Item.search_index.refresh
    Essence.search_index.refresh
  end

  def grant_then_revoke_collection_user
    collection_user = Permission.create!(grantable: collection, user:, level: :read)
    refresh_search_indexes
    collection_user.destroy!
    refresh_search_indexes
  end

  def grant_then_revoke_item_user
    item_user = Permission.create!(grantable: item, user:, level: :read)
    refresh_search_indexes
    item_user.destroy!
    refresh_search_indexes
  end

  # A collection read grant lands in the access_user_ids union of the collection and every item in
  # it (and their essences), so all those indexes must follow the grant.
  describe 'a collection user grant' do
    context 'when no grant exists' do
      before { visit search_collections_path }

      it 'hides the private collection' do
        expect(page).to have_no_text(collection.identifier)
      end
    end

    context 'when access has been granted' do
      before do
        Permission.create!(grantable: collection, user:, level: :read)
        refresh_search_indexes
      end

      it 'reveals the collection in collection search' do
        visit search_collections_path
        expect(page).to have_text(collection.identifier)
      end

      it 'reveals its items in item search' do
        visit search_items_path
        expect(page).to have_text(item.full_identifier)
      end
    end

    context 'when a granted collection user has been revoked' do
      before do
        grant_then_revoke_collection_user
        visit search_collections_path
      end

      it 'hides the collection again' do
        expect(page).to have_no_text(collection.identifier)
      end
    end

    context 'when a revoked collection user looks at item search' do
      before do
        grant_then_revoke_collection_user
        visit search_items_path
      end

      it 'hides its items again' do
        expect(page).to have_no_text(item.full_identifier)
      end
    end
  end

  # An item read grant lands in the access_user_ids union of the item and its collection.
  describe 'an item user grant' do
    context 'when no grant exists' do
      before { visit search_items_path }

      it 'hides the private item' do
        expect(page).to have_no_text(item.full_identifier)
      end
    end

    context 'when access has been granted' do
      before do
        Permission.create!(grantable: item, user:, level: :read)
        refresh_search_indexes
      end

      it 'reveals the item in item search' do
        visit search_items_path
        expect(page).to have_text(item.full_identifier)
      end

      it 'reveals its collection in collection search' do
        visit search_collections_path
        expect(page).to have_text(collection.identifier)
      end
    end

    context 'when a granted item user has been revoked' do
      before do
        grant_then_revoke_item_user
        visit search_items_path
      end

      it 'hides the item again' do
        expect(page).to have_no_text(item.full_identifier)
      end
    end
  end
end
