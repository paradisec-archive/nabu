# rubocop:disable Metrics/AbcSize,Metrics/MethodLength
class Ability
  include CanCan::Ability

  def initialize(user)
    #############
    # Guests
    #############

    if user.nil?
      can :read, Collection, private: false
      can %i[read data], Item, { private: false, collection: { private: false } }
      can :read, Entity, private: false

      return
    end

    #############
    # PARADISEC admins
    #############
    if user.admin?
      can :manage, :all

      return
    end

    #############
    # Users
    #############

    # Users can manage themselves
    can :manage, User, id: user.id
    can :read, User

    #############
    # Meta data models
    #############

    # Anyone can create a university
    # FIXME: normal users shouldn't be able to create universities
    can :create, University

    # Anyone can read these entities - need them for creation
    can :read, Language
    can :read, Country
    can :read, DataCategory
    # DataType seems to work fine without this `can` statement, but include it for consistency.
    can :read, DataType
    can :read, DiscourseType


    #############
    # Entities
    #############

    # Public entities can be read by anyone
    can :read, Entity, private: false

    #############
    # Collections
    #############

    # Anyone can view non-private collections
    can :read, Collection, private: false
    can :read, Entity, entity_type: 'Collection', collection: { private: false }

    # Members of any item in a collection can read the collection
    can :read, Collection, items: { item_users: { user_id: user.id } }
    can :read, Entity, entity_type: 'Collection', collection: { items: { item_users: { user_id: user.id } } }
    can :read, Collection, items: { item_admins: { user_id: user.id } }
    can :read, Entity, entity_type: 'Collection', collection: { items: { item_admins: { user_id: user.id } } }
    can %i[read update], Collection, collection_admins: { user_id: user.id }
    can :read, Entity, entity_type: 'Collection', collection: { collection_admins: { user_id: user.id } }

    # collection_users are read-only grantees of the whole collection
    can :read, Collection, collection_users: { user_id: user.id }
    can :read, Entity, entity_type: 'Collection', collection: { collection_users: { user_id: user.id } }

    # Only admins can create a collection
    cannot :create, Collection

    can :advanced_search, Collection
    cannot :search_csv, Collection
    cannot :bulk_edit, Collection
    cannot :bulk_update, Collection


    #############
    # Items
    #############

    # NOTE: these Item :read grants are the canonical visibility policy. The search indexes
    # mirror them via denormalised id fields (Item.search_user_fields -> admin_ids, user_ids,
    # collection_user_ids, collection_admin_ids) consumed by HasSearch#visibility_clauses.
    # If you add or remove a read path here, update the matching index field and
    # spec/features/search_authorisation_consistency_spec.rb, which pins the two together.
    can %i[read data], Item, { private: false, collection: { private: false } }
    can :read, Entity, entity_type: 'Item', item: { private: false, collection: { private: false } }

    can %i[read data], Item, item_users: { user_id: user.id }
    can :read, Entity, entity_type: 'Item', item: { item_users: { user_id: user.id } }
    can %i[read data], Item, item_admins: { user_id: user.id }
    can :read, Entity, entity_type: 'Item', item: { item_admins: { user_id: user.id } }

    can %i[read data], Item, collection: { collection_users: { user_id: user.id } }
    can :read, Entity, entity_type: 'Item', item: { collection: { collection_users: { user_id: user.id } } }

    can :manage, Item, collection: { collection_admins: { user_id: user.id } }
    can :read, Entity, entity_type: 'Item', item: { collection: { collection_admins: { user_id: user.id } } }
    can :manage, Item, item_admins: { user_id: user.id }
    can :read, Entity, entity_type: 'Item', item: { item_admins: { user_id: user.id } }

    can :advanced_search, Item
    can :new_report, Item
    can :send_report, Item
    can :report_sent, Item
    can :graphql, Item

    cannot :search_csv, Item
    cannot :bulk_edit, Item
    cannot :bulk_update, Item

    cannot :essences_csv, Collection
    cannot :essences_csv, Item

    #############
    # Essence
    #############

    can %i[read download display entities], Essence,
      item: { access_condition: { name: 'Open (subject to agreeing to PDSC access conditions)' } }
    can %i[read download], Entity, entity_type: 'Essence', essence: { item: { access_condition: { name: 'Open (subject to agreeing to PDSC access conditions)' } } }
    can %i[read download display], Essence, item: { collection: { collection_admins: { user_id: user.id } } }
    can %i[read download], Entity, entity_type: 'Essence', essence: { item: { collection: { collection_admins: { user_id: user.id } } } }
    can %i[read download display], Essence, item: { collection: { collection_users: { user_id: user.id } } }
    can %i[read download], Entity, entity_type: 'Essence', essence: { item: { collection: { collection_users: { user_id: user.id } } } }
    can %i[read download display], Essence, item: { item_admins: { user_id: user.id } }
    can %i[read download], Entity, entity_type: 'Essence', essence: { item: { item_admins: { user_id: user.id } } }
    can %i[read download display], Essence, item: { item_users: { user_id: user.id } }
    can %i[read download], Entity, entity_type: 'Essence', essence: { item: { item_users: { user_id: user.id } } }

    can :create, Comment, commentable: { private: false }

    #############
    # EssenceAnnotation
    #############

    can :manage, EssenceAnnotation, target_essence: { item: { item_admins: { user_id: user.id } } }
    can :manage, EssenceAnnotation, target_essence: { item: { collection: { collection_admins: { user_id: user.id } } } }
  end
end
# rubocop:enable Metrics/AbcSize,Metrics/MethodLength
