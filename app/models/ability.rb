# rubocop:disable Metrics/AbcSize,Metrics/MethodLength
class Ability
  include CanCan::Ability

  def initialize(user)
    #############
    # Guests
    #############

    unless user
      can :read, Collection, private: false
      can %i[read data], Item, { private: false, collection: { private: false } }

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
    can :create, University

    # Anyone can read these entities - need them for creation
    can :read, Language
    can :read, Country
    can :read, DataCategory
    # DataType seems to work fine without this `can` statement, but include it for consistency.
    can :read, DataType
    can :read, DiscourseType

    #############
    # Collections
    #############

    # Only collection_admins can manage a collection
    can :read,   Collection, items: { item_users: { user_id: user.id } }
    can :read,   Collection, items: { item_admins: { user_id: user.id } }
    can %i[read update], Collection, collection_admins: { user_id: user.id }
    can %i[read update], Collection, operator_id: user.id
    can %i[read update], Collection, collector_id: user.id

    # Only admins can create a collection
    cannot :create, Collection

    can :advanced_search, Collection
    cannot :search_csv, Collection
    cannot :bulk_edit, Collection
    cannot :bulk_update, Collection

    # Anyone can view non-private collections
    can :read, Collection, private: false

    #############
    # Items
    #############

    can %i[read data], Item, { private: false, collection: { private: false } }
    can %i[read data], Item, item_users: { user_id: user.id }
    can %i[read data], Item, item_admins: { user_id: user.id }
    can :manage, Item, collector_id: user.id
    can :manage, Item, operator_id: user.id
    can :manage, Item, collection: { collection_admins: { user_id: user.id } }
    can :manage, Item, collection: { collector_id: user.id }
    can :manage, Item, collection: { operator_id: user.id }
    can :manage, Item, item_admins: { user_id: user.id }

    can :advanced_search, Item
    can :new_report, Item
    can :send_report, Item
    can :report_sent, Item
    can :graphql, Item

    cannot :search_csv, Item
    cannot :bulk_edit, Item
    cannot :bulk_update, Item

    #############
    # Essence
    #############

    can %i[read download show_terms agree_to_terms display],  Essence,
        item: { access_condition: { name: 'Open (subject to agreeing to PDSC access conditions)' } }
    can %i[read download show_terms agree_to_terms display],  Essence,
        item: { access_condition: { name: 'Open (subject to the access condition details)' } }
    can %i[read download display], Essence, item: { collection: { collection_admins: { user_id: user.id } } }
    can %i[read download display], Essence, item: { collection: { collector_id: user.id } }
    can %i[read download display], Essence, item: { item_admins: { user_id: user.id } }
    can %i[read download display], Essence, item: { item_users: { user_id: user.id } }

    can :create, Comment, commentable: { private: false }
  end
end
# rubocop:enable Metrics/AbcSize,Metrics/MethodLength
