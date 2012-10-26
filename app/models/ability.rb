class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.new_record? # Guests
      can :read, Collection, :private => false
      can :read, Item,       :private => false
    elsif user.admin? # System admins
      can :manage, :all
    else
      # Users can manage themseleves
      can :manage, User, :id => user.id
      can :read, User

      # Anyone can create a university
      can :create, University

      # Anyone can create a collection
      can :create, Collection

      # Anyone can view non-private collections
      can :read, Collection, :private => false

      # Anyone can read these entities - need them for creation
      can :read, Language
      can :read, Country
      can :read, DataCategory
      can :read, DiscourseType

      # Only collection_admins can manage a collection
      can :manage, Collection, :collection_admins => { :user_id => user.id }
      can :manage, Collection, :operator_id => user.id
      can :manage, Collection, :collector_id => user.id
      cannot :search_csv, Collection
      cannot :advanced_search, Collection
      cannot :bulk_edit, Collection
      cannot :bulk_update, Collection

      can :read,   Item, :private => false
      can :manage, Item, :collector_id => user.id
      can :manage, Item, :operator_id => user.id
      can :manage, Item, :collection  => { :collection_admins => { :user_id => user.id } }
      can :manage, Item, :collection  => { :collector_id => user.id }
      can :manage, Item, :collection  => { :operator_id => user.id }
      can :manage, Item, :item_admins => { :user_id => user.id }
      cannot :search_csv, Item
      cannot :advanced_search, Item
      cannot :bulk_edit, Item
      cannot :bulk_update, Item

      can [:read, :display],  Essence, :item => { :private => false }
      can [:read, :download, :display], Essence, :item => { :collection  => { :collection_admins => { :user_id => user.id } } }
      can [:read, :download, :display], Essence, :item => { :collection  => { :collector_id => user.id } }
      can [:read, :download, :display], Essence, :item => { :item_admins => { :user_id => user.id } }

      can :create, Comment, :commentable => { :private => false }
    end
  end
end
