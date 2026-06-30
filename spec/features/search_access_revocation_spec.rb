require 'rails_helper'

# Regression coverage for the denormalised permission fields in the search indexes.
# Collection, Item and Essence search documents each embed the ids of the users allowed to
# see them (user_ids, admin_ids, collection_user_ids, item_user_ids, ...). When a grant is
# added or removed the affected documents must be reindexed, otherwise a revoked user keeps
# finding private records via search. The reindex is driven by
# CollectionUser/CollectionAdmin/ItemUser/ItemAdmin#reindex_search_documents.
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
    collection_user = CollectionUser.create!(collection:, user:)
    refresh_search_indexes
    collection_user.destroy!
    refresh_search_indexes
  end

  def grant_then_revoke_item_user
    item_user = ItemUser.create!(item:, user:)
    refresh_search_indexes
    item_user.destroy!
    refresh_search_indexes
  end

  # A collection user is denormalised onto the collection (user_ids) and every item in it
  # (collection_user_ids), so both indexes must follow the grant.
  describe 'a collection user grant' do
    context 'when no grant exists' do
      before { visit search_collections_path }

      it 'hides the private collection' do
        expect(page).to have_no_text(collection.identifier)
      end
    end

    context 'when access has been granted' do
      before do
        CollectionUser.create!(collection:, user:)
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

  # An item user is denormalised onto the item (user_ids) and its collection (item_user_ids).
  describe 'an item user grant' do
    context 'when no grant exists' do
      before { visit search_items_path }

      it 'hides the private item' do
        expect(page).to have_no_text(item.full_identifier)
      end
    end

    context 'when access has been granted' do
      before do
        ItemUser.create!(item:, user:)
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
