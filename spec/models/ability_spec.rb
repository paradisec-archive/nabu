require 'rails_helper'
require 'cancan/matchers'

# These specs assert external authorisation behaviour — what a given actor can and
# cannot do — rather than the internal shape of the membership tables, so they stay
# valid if those tables are later restructured (Phase 2).
RSpec.describe Ability do
  def ability(actor = user)
    described_class.new(actor)
  end

  def open_access
    create(:access_condition, name: 'Open (subject to agreeing to PDSC access conditions)')
  end

  def closed_access
    create(:access_condition, name: 'Closed')
  end

  def private_collection(**attrs)
    create(:collection, private: true, **attrs)
  end

  def closed_item(**attrs)
    create(:item, access_condition: closed_access, private: true, **attrs)
  end

  # The denormalised Entity record the API authorises against.
  def entity_for(record)
    Entity.find_by!(entity_type: record.class.name, entity_id: record.id)
  end

  describe 'collection collector attribution confers no rights' do
    let(:user) { create(:user) }
    let(:collection) { private_collection(collector: user) }
    let(:item) { closed_item(collection:, collector: user, operator: user) }
    let(:essence) { create(:sound_essence, item:) }

    it 'cannot read or update the private collection' do
      aggregate_failures do
        expect(ability).not_to be_able_to(:read, collection)
        expect(ability).not_to be_able_to(:update, collection)
      end
    end

    it 'cannot manage the collection items' do
      expect(ability).not_to be_able_to(:manage, item)
    end

    it 'cannot download the items essences' do
      expect(ability).not_to be_able_to(:download, essence)
    end

    it 'cannot manage essence annotations' do
      expect(ability).not_to be_able_to(:manage, EssenceAnnotation.new(target_essence: essence))
    end
  end

  describe 'collection operator attribution confers no rights' do
    let(:user) { create(:user) }
    let(:collection) { private_collection(operator: user) }
    let(:item) { closed_item(collection:, operator: user) }

    it 'cannot read or update the private collection' do
      aggregate_failures do
        expect(ability).not_to be_able_to(:read, collection)
        expect(ability).not_to be_able_to(:update, collection)
      end
    end

    it 'cannot manage the collection items' do
      expect(ability).not_to be_able_to(:manage, item)
    end
  end

  describe 'item collector attribution confers no rights' do
    let(:user) { create(:user) }
    let(:item) { closed_item(collection: private_collection, collector: user) }

    it 'cannot manage the item' do
      aggregate_failures do
        expect(ability).not_to be_able_to(:manage, item)
        expect(ability).not_to be_able_to(:update, item)
      end
    end
  end

  describe 'collection editor (collection_admins) retains edit' do
    let(:user) { create(:user) }
    let(:collection) { private_collection }
    let(:item) { closed_item(collection:) }
    let(:essence) { create(:sound_essence, item:) }

    before { collection.admins << user }

    it 'can read and update the collection and manage its items' do
      aggregate_failures do
        expect(ability).to be_able_to(:update, collection)
        expect(ability).to be_able_to(:manage, item)
      end
    end

    it 'can download essences via the primary rule' do
      expect(ability).to be_able_to(:download, essence)
    end
  end

  describe 'collection read-only grantee (collection_users) gets cascading read' do
    let(:user) { create(:user) }
    let(:collection) { private_collection }
    let(:item) { closed_item(collection:) }
    let(:essence) { create(:sound_essence, item:) }

    before { collection.users << user }

    it 'can read the collection, its private items and the item data view' do
      aggregate_failures do
        expect(ability).to be_able_to(:read, collection)
        expect(ability).to be_able_to(:read, item)
        expect(ability).to be_able_to(:data, item)
      end
    end

    it 'can read, download and display the closed essences' do
      aggregate_failures do
        expect(ability).to be_able_to(:read, essence)
        expect(ability).to be_able_to(:download, essence)
        expect(ability).to be_able_to(:display, essence)
      end
    end

    it 'gets the same read/download via the denormalised Entity records' do
      aggregate_failures do
        expect(ability).to be_able_to(:read, entity_for(collection))
        expect(ability).to be_able_to(:read, entity_for(item))
        expect(ability).to be_able_to(:download, entity_for(essence))
      end
    end

    it 'cannot edit the collection or its items' do
      aggregate_failures do
        expect(ability).not_to be_able_to(:update, collection)
        expect(ability).not_to be_able_to(:update, item)
      end
    end

    it 'cannot manage essence annotations' do
      expect(ability).not_to be_able_to(:manage, EssenceAnnotation.new(target_essence: essence))
    end
  end

  # Regression for NABU-QK: the instance-level be_able_to checks above never build SQL, but the
  # Oni API authorises lists with Entity.accessible_by. That query joins the polymorphic permissions
  # table once per access path; when the collection-grant join appeared three times (Collection,
  # Item and Essence paths) CanCanCan mis-aliased the deepest join and .count raised
  # ActiveRecord::StatementInvalid ("Unknown column 'collection_permissions_collections_2_3...'").
  describe 'Entity.accessible_by builds valid SQL for a non-admin' do
    let(:user) { create(:user) }
    let(:collection) { private_collection }
    let(:item) { closed_item(collection:) }
    let!(:essence) { create(:sound_essence, item:) }

    before { collection.users << user }

    it 'lists the accessible essence entities without raising, scoped to the grant' do
      stranger_essence = create(:sound_essence, item: closed_item(collection: private_collection))

      accessible = nil
      aggregate_failures do
        expect { accessible = Entity.accessible_by(ability).where(entity_type: 'Essence').to_a }.not_to raise_error
        expect(accessible).to include(entity_for(essence))
        expect(accessible).not_to include(entity_for(stranger_essence))
      end
    end
  end

  describe 'item editor (item_admins) retains edit and download' do
    let(:user) { create(:user) }
    let(:item) { closed_item(collection: private_collection) }
    let(:essence) { create(:sound_essence, item:) }

    before { item.admins << user }

    it 'can manage the item and download its essences' do
      aggregate_failures do
        expect(ability).to be_able_to(:manage, item)
        expect(ability).to be_able_to(:download, essence)
      end
    end

    it 'can manage essence annotations' do
      expect(ability).to be_able_to(:manage, EssenceAnnotation.new(target_essence: essence))
    end
  end

  describe 'item read-only grantee (item_users) retains read and download' do
    let(:user) { create(:user) }
    let(:item) { closed_item(collection: private_collection) }
    let(:essence) { create(:sound_essence, item:) }

    before { item.users << user }

    it 'can read the item and download its closed essences but cannot edit' do
      aggregate_failures do
        expect(ability).to be_able_to(:read, item)
        expect(ability).to be_able_to(:download, essence)
        expect(ability).not_to be_able_to(:update, item)
      end
    end
  end

  describe 'guests are unchanged' do
    let(:user) { nil }
    let(:public_collection) { create(:collection, private: false) }
    let(:public_item) { create(:item, private: false, access_condition: open_access, collection: public_collection) }

    it 'can read public collections and items but not private ones' do
      aggregate_failures do
        expect(ability).to be_able_to(:read, public_collection)
        expect(ability).to be_able_to(:read, public_item)
        expect(ability).not_to be_able_to(:read, private_collection)
      end
    end
  end

  describe 'admins are unchanged' do
    let(:user) { create(:admin_user) }
    let(:collection) { private_collection }
    let(:item) { closed_item(collection:) }
    let(:essence) { create(:sound_essence, item:) }

    it 'can manage everything including closed essences' do
      aggregate_failures do
        expect(ability).to be_able_to(:manage, collection)
        expect(ability).to be_able_to(:manage, item)
        expect(ability).to be_able_to(:manage, essence)
      end
    end
  end
end
