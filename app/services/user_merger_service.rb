class UserMergerService
  def initialize(user, duplicates)
    # make sure we don't accidentally destroy target user
    @user = user
    @duplicates = duplicates.present? ? duplicates.reject {|d| d.id == user.id} : nil
  end

  def call
    return if @duplicates.nil? or @duplicates.empty?

    reassign_ownership(@duplicates.collect(&:id))

    Rails.logger.debug 'Destroying duplicate users, now that they have been merged'
    @duplicates.each(&:destroy)

    Rails.logger.debug 'Updating primary user, now that the duplicates have been removed'
    @user.save
  end

  private

  def reassign_ownership(dup_ids)
    Rails.logger.debug "Reassigning item permissions from #{dup_ids.inspect} to #{@user.id}"

    #set all fields referencing old duplicates to point to new primary user
    Item.update_all({collector_id: @user.id}, {collector_id: dup_ids})
    Item.update_all({operator_id: @user.id}, {operator_id: dup_ids})
    ItemUser.update_all({user_id: @user.id}, {user_id: dup_ids})
    ItemAdmin.update_all({user_id: @user.id}, {user_id: dup_ids})
    ItemAgent.update_all({user_id: @user.id}, {user_id: dup_ids})
  end
end