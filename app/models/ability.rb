# Authorisation policy for Nabu — the single source of truth for "who can do what".
#
# CORE PRINCIPLE: attribution is not access.
#   The `collector` and `operator` fields (on collections and items) and item agents are
#   pure historical metadata — they record *who did the work* and confer NO rights. All
#   access comes from explicit, admin-assigned grants. Nothing here keys off collector_id
#   or operator_id; if you find yourself adding such a rule, stop — that was Phase 1's bug.
#
# ACCESS TIERS (each tier is a superset of the one above):
#
#   Tier      | View private | Download incl. closed | Edit | Preservation masters
#   --------- | ------------ | --------------------- | ---- | --------------------
#   Read-only | yes          | yes                   | no   | no
#   Edit      | yes          | yes                   | yes  | no
#   Admin     | yes          | yes                   | yes  | yes
#
# Each non-admin tier is backed by a membership join table (user_id + the record):
#
#   Tier      | Collection level  | Item level
#   --------- | ----------------- | ----------
#   Read-only | collection_users  | item_users
#   Edit      | collection_admins | item_admins
#
#   A collection_users grant CASCADES to every item in the collection and its essences —
#   see the `collection: { collection_users: ... }` rules below. Admin is the `admin`
#   boolean on User and short-circuits everything via `can :manage, :all`.
#
# CROSS-CUTTING RULES — enforced elsewhere, noted here so the whole policy reads in one place:
#   * Preservation masters (.mxf/.mkv, Essence#is_archived?) are admin-only. NOT enforced
#     here — see EssencesController#download/#display and Api::V1::OniController, which
#     reject non-admins regardless of any grant below.
#   * Contacts (contact_only users) can never hold a grant. Enforced by the
#     RejectsContactGrants concern on the four membership models, not here.
#   * Grant assignment is admin-only — the grant fields are admin-gated in the collection
#     and item controllers/forms, so a non-admin's save never adds or removes a grant.
#
# SEARCH VISIBILITY: the :read rules here are the canonical policy; the search indexes
#   mirror them via denormalised id fields (see the Item note below and
#   spec/features/search_authorisation_consistency_spec.rb). Change a read path here and
#   you must update the matching index field and that spec.
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
