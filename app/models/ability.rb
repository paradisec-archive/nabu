class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)

    if user.new_record?
      can :read, Collection, :private => false
      can :read, Item,       :private => false
    elsif user.admin?
      can :manage, :all
    else
      can :manage, User, :id => user.id
      cannot :index, User
      can :create, Collection
      can :read, Collection, :private => false
      can :manage, Collection, :collection_admins => { :user_id => user.id }

      can :create, Item, :collection => {:collection_admins => { :user_id => user.id } }
      can :read, Item,       :private => false
      can :manage, Item,       :item_admins => { :user_id => user.id }
    end
  end
end
