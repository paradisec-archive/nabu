require 'rails_helper'

# Slice 6 of Permissions Phase 2: the item show/edit views gain a read-only "Inherited from
# collection" block. With the item-edit prefill removed, a collection's editors are no longer
# copied down as item-level rows, so the block makes it obvious which access cascades from the
# collection. It never creates or alters an item-level Permission.
describe 'Item inherited-from-collection access' do
  let(:admin_user) { create(:admin_user) }
  let(:collection_editor) { create(:user, first_name: 'Edith', last_name: 'Editor') }
  let(:collection_reader) { create(:user, first_name: 'Reba', last_name: 'Reader') }
  let(:collection) { create(:collection) }
  let(:item) { create(:item, collection:) }

  before do
    collection.admins << collection_editor
    collection.users << collection_reader
  end

  def inherited_block(user, path)
    sign_in user
    visit path
    find('fieldset.inherited-access')
  end

  describe 'item show' do
    it "lists the collection's editors and read grantees" do
      block = inherited_block(admin_user, collection_item_path(collection, item))
      aggregate_failures do
        expect(block).to have_text(collection_editor.name)
        expect(block).to have_text(collection_reader.name)
      end
    end

    it 'shows the manage-on-the-collection link to users who can manage the collection' do
      block = inherited_block(admin_user, collection_item_path(collection, item))
      aggregate_failures do
        expect(block).to have_text('Inherited from collection')
        expect(block).to have_link('Manage access on the collection', href: edit_collection_path(collection))
      end
    end

    it 'hides the manage-on-the-collection link from users who cannot manage the collection' do
      block = inherited_block(collection_editor, collection_item_path(collection, item))
      aggregate_failures do
        expect(block).to have_text(collection_editor.name)
        expect(block).to have_no_link('Manage access on the collection')
      end
    end

    it 'does not create any item-level Permission for the inherited grantees' do
      inherited_block(admin_user, collection_item_path(collection, item))
      aggregate_failures do
        expect(item.reload.admins).to be_empty
        expect(item.users).to be_empty
      end
    end
  end

  describe 'item edit' do
    it "renders the same 'Inherited from collection' block in edit mode" do
      block = inherited_block(admin_user, edit_collection_item_path(collection, item))
      aggregate_failures do
        expect(block).to have_text(collection_editor.name)
        expect(block).to have_link('Manage access on the collection', href: edit_collection_path(collection))
      end
    end
  end
end
