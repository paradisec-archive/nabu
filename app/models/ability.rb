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
      # but can't see list of users
      cannot :index, User

      # Anyone can create a university
      can :create, University

      # Anyone can create a collection
      can :create, Collection
      # Anyone can view non-private collections
      can :read, Collection, :private => false
      can :advanced_search, Collection

      # Only collection_admins can manage a collection
      can :manage, Collection, :collection_admins => { :user_id => user.id }
      can :manage, Collection, :collector_id => user.id

      can :read, Item, :private => false
      can :manage, Item, :collection  => { :collection_admins => { :user_id => user.id } }
      can :manage, Item, :collection  => { :collector_id => user.id }
      can :manage, Item, :item_admins => { :user_id => user.id }

      can :create, Comment, :commentable => { :private => false }
    end
  end
end
