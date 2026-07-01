require 'rails_helper'
require 'cancan/matchers'

# Consistency oracle between Ability (the canonical read policy) and the search indexes.
#
# Ability (app/models/ability.rb) is the single source of truth for who may :read a
# Collection or Item. The search indexes filter results separately, using denormalised
# permission fields (admin_ids, user_ids, collection_user_ids, collection_admin_ids,
# item_admin_ids, item_user_ids) consumed by HasSearch#visibility_clauses.
#
# Those two mechanisms must agree: every relationship that Ability says grants :read must
# also make the record findable in search, and vice versa. This spec pins them together so
# they cannot drift - if you add a new read grant to ability.rb, add the matching index field
# (and a row here) or this spec fails. See the cross-reference notes in ability.rb and
# app/controllers/concerns/has_search.rb.
describe 'Search/Ability authorisation consistency', :search do
  let!(:user) { create(:user) }
  let!(:collection) { create(:collection, identifier: 'PRIVCOLL', private: true) }
  let!(:item) { create(:item, identifier: 'SECRETITEM', collection:, private: true) }

  before { login_as user, scope: :user }

  # Make whatever the reindex callbacks have already written visible to search, without
  # reindexing ourselves - that way we exercise the production callbacks, not the test setup.
  def refresh_search_indexes
    Collection.search_index.refresh
    Item.search_index.refresh
  end

  # Advanced search builds a query from text fields, so give it a term that matches the item;
  # with no term the result list is not rendered. The user filter still applies on top.
  def visit_advanced_item_search
    visit advanced_search_items_path(full_identifier: item.identifier)
  end

  # Every relationship that ability.rb grants :read on a private Item through.
  item_grants = {
    'item admin' => ->(item, user) { Permission.create!(grantable: item, user:, level: :edit) },
    'item user' => ->(item, user) { Permission.create!(grantable: item, user:, level: :read) },
    'collection user' => ->(item, user) { Permission.create!(grantable: item.collection, user:, level: :read) },
    'collection admin' => ->(item, user) { Permission.create!(grantable: item.collection, user:, level: :edit) }
  }

  # Every relationship that ability.rb grants :read on a private Collection through.
  collection_grants = {
    'collection admin' => ->(collection, user) { Permission.create!(grantable: collection, user:, level: :edit) },
    'collection user' => ->(collection, user) { Permission.create!(grantable: collection, user:, level: :read) },
    'item admin' => ->(collection, user) { Permission.create!(grantable: collection.items.reload.first, user:, level: :edit) },
    'item user' => ->(collection, user) { Permission.create!(grantable: collection.items.reload.first, user:, level: :read) }
  }

  describe 'a private item' do
    it 'is denied read by ability when there is no grant' do
      expect(Ability.new(user)).not_to be_able_to(:read, item)
    end

    context 'when no grant exists, in basic item search' do
      before { visit search_items_path }

      it 'hides the item' do
        expect(page).to have_no_text(item.full_identifier)
      end
    end

    context 'when no grant exists, in advanced item search' do
      before { visit_advanced_item_search }

      it 'hides the item' do
        expect(page).to have_no_text(item.full_identifier)
      end
    end

    item_grants.each do |relationship, grant|
      context "when the user is a #{relationship}" do
        before do
          grant.call(item, user)
          refresh_search_indexes
        end

        it 'is granted read by ability' do
          expect(Ability.new(user)).to be_able_to(:read, item.reload)
        end

        it 'is visible in basic item search' do
          visit search_items_path
          expect(page).to have_text(item.full_identifier)
        end

        it 'is visible in advanced item search' do
          visit_advanced_item_search
          expect(page).to have_text(item.full_identifier)
        end
      end
    end
  end

  describe 'a private collection' do
    it 'is denied read by ability when there is no grant' do
      expect(Ability.new(user)).not_to be_able_to(:read, collection)
    end

    context 'when no grant exists, in basic collection search' do
      before { visit search_collections_path }

      it 'hides the collection' do
        expect(page).to have_no_text(collection.identifier)
      end
    end

    collection_grants.each do |relationship, grant|
      context "when the user is a #{relationship}" do
        before do
          grant.call(collection, user)
          refresh_search_indexes
        end

        it 'is granted read by ability' do
          expect(Ability.new(user)).to be_able_to(:read, collection.reload)
        end

        it 'is visible in basic collection search' do
          visit search_collections_path
          expect(page).to have_text(collection.identifier)
        end
      end
    end
  end
end
