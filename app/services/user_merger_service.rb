class UserMergerService
  def initialize(user, duplicates)
    # make sure we don't accidentally destroy target user
    @user = user
    @duplicates = duplicates.present? ? duplicates.reject { |d| d.id == user.id } : nil
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

    # set all fields referencing old duplicates to point to new primary user
    Item.where(collector_id: dup_ids).update_all(collector_id: @user.id)
    Item.where(operator_id: dup_ids).update_all(operator_id: @user.id)
    # Access grants (collection/item, read/edit) now all live in the polymorphic permissions
    # table, so one pass moves every grant the duplicates held onto the primary. A grant the
    # primary already holds is dropped rather than duplicated, so the (user, grantable, level)
    # unique index is never violated. update_columns/delete skip callbacks, matching the old
    # bulk update_all (a single reindex follows a merge, as before).
    held = Permission.where(user_id: @user.id).pluck(:grantable_type, :grantable_id, :level).to_set
    Permission.where(user_id: dup_ids).find_each do |permission|
      key = [permission.grantable_type, permission.grantable_id, permission.level]
      if held.include?(key)
        permission.delete
      else
        permission.update_columns(user_id: @user.id)
        held << key
      end
    end
    ItemAgent.where(user_id: dup_ids).update_all(user_id: @user.id)
  end
end
