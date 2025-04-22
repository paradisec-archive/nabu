namespace :users do
  def self.find_unlinked_unconfirmed_users(min_age_days = 0)
    puts "Finding unconfirmed users older than #{min_age_days} days who aren't referenced anywhere..."

    # Calculate the cutoff date
    cutoff_date = Time.now - min_age_days.days
    
    # Get all unconfirmed users except contact_only users, created before the cutoff date
    query = User.where(contact_only: false, confirmed_at: nil)
                .where('created_at < ?', cutoff_date)
    
    all_unconfirmed_users = query.pluck(:id)
    puts "Total unconfirmed users older than #{min_age_days} days: #{all_unconfirmed_users.count}"

    # Find users referenced in various tables
    used_users = Set.new

    # Collection bits
    used_users.merge(Collection.pluck(:collector_id))
    used_users.merge(Collection.where.not(operator_id: nil).pluck(:operator_id))
    used_users.merge(CollectionAdmin.pluck(:user_id))

    # Item bits
    used_users.merge(Item.pluck(:collector_id))
    used_users.merge(Item.where.not(operator_id: nil).pluck(:operator_id))
    used_users.merge(ItemAdmin.pluck(:user_id))
    used_users.merge(ItemAgent.pluck(:user_id))
    used_users.merge(ItemUser.pluck(:user_id))

    # Comment owners
    used_users.merge(Comment.pluck(:owner_id))

    # User bits
    used_users.merge(PartyIdentifier.pluck(:user_id))
    used_users.merge(User.where.not(rights_transferred_to_id: nil).pluck(:rights_transferred_to_id))

    # Downloads
    used_users.merge(Download.pluck(:user_id))

    # Find unused and used unconfirmed users
    used_unconfirmed_users = all_unconfirmed_users & used_users.to_a
    unused_unconfirmed_users = all_unconfirmed_users - used_users.to_a

    puts "Referenced unconfirmed users: #{used_unconfirmed_users.count}"
    puts "Unused unconfirmed users: #{unused_unconfirmed_users.count}"

    {
      used: used_unconfirmed_users,
      unused: unused_unconfirmed_users
    }
  end

  desc 'List all unconfirmed users who are at risk of deletion (older than 7 days and not referenced)'
  task list_warn: [:environment] do
    puts 'Warning: These users will be deleted next week if they remain unconfirmed'

    result = self.find_unlinked_unconfirmed_users(7)
    unused_unconfirmed_users = result[:unused]
    
    if unused_unconfirmed_users.any?
      puts "\nUnused unconfirmed users at risk of deletion:"
      unused_unconfirmed_users.each do |user_id|
        user = User.find(user_id)
        created_days_ago = ((Time.now - user.created_at) / 86400).to_i
        puts "ID: #{user.id}, Name: #{user.name}, Email: #{user.email || 'No email'}, Created: #{user.created_at.to_date} (#{created_days_ago} days ago)"
      end
      
      # Count users older than 14 days who will be deleted next week
      delete_candidates = unused_unconfirmed_users.count do |user_id|
        user = User.find(user_id)
        (Time.now - user.created_at) >= 14.days
      end
      
      puts "\nOf these, #{delete_candidates} users are already older than 14 days and would be deleted immediately if you run the delete task."
    else
      puts 'No unused unconfirmed users found.'
    end
  end

  desc 'List unconfirmed users who would be deleted (older than 14 days and not referenced)'
  task list_unused: [:environment] do
    puts 'List the unused users who will be deleted (older than 14 days)...'

    result = self.find_unlinked_unconfirmed_users(14)
    used_unconfirmed_users = result[:used]
    unused_unconfirmed_users = result[:unused]

    # Print referenced unconfirmed user details
    if used_unconfirmed_users.any?
      puts "\nReferenced unconfirmed user details:"
      used_unconfirmed_users.each do |user_id|
        user = User.find(user_id)
        created_days_ago = ((Time.now - user.created_at) / 86400).to_i
        puts "ID: #{user.id}, Name: #{user.name}, Email: #{user.email || 'No email'}, Created: #{user.created_at.to_date} (#{created_days_ago} days ago)"

        # Find where this user is referenced
        references = []
        references << 'Collection collector' if Collection.where(collector_id: user_id).exists?
        references << 'Collection operator' if Collection.where(operator_id: user_id).exists?
        references << 'CollectionAdmin' if CollectionAdmin.where(user_id: user_id).exists?
        references << 'Item collector' if Item.where(collector_id: user_id).exists?
        references << 'Item operator' if Item.where(operator_id: user_id).exists?
        references << 'ItemAdmin' if ItemAdmin.where(user_id: user_id).exists?
        references << 'ItemAgent' if ItemAgent.where(user_id: user_id).exists?
        references << 'ItemUser' if ItemUser.where(user_id: user_id).exists?
        references << 'Comment owner' if Comment.where(owner_id: user_id).exists?
        references << 'PartyIdentifier' if PartyIdentifier.where(user_id: user_id).exists?
        references << 'Rights transferred to' if User.where(rights_transferred_to_id: user_id).exists?
        references << 'Download' if Download.where(user_id: user_id).exists?

        puts "  Referenced as: #{references.join(', ')}"
      end
    else
      puts 'No referenced unconfirmed users found.'
    end

    # Print unused unconfirmed user details
    if unused_unconfirmed_users.any?
      puts "\nUnused unconfirmed user details (these will be deleted):"
      unused_unconfirmed_users.each do |user_id|
        user = User.find(user_id)
        created_days_ago = ((Time.now - user.created_at) / 86400).to_i
        puts "ID: #{user.id}, Name: #{user.name}, Email: #{user.email || 'No email'}, Created: #{user.created_at.to_date} (#{created_days_ago} days ago)"
      end
    else
      puts 'No unused unconfirmed users found.'
    end
  end

  desc 'Delete unconfirmed users who are older than 14 days and not referenced in any tables'
  task delete_unused: [:environment] do
    puts 'Deleting unused unconfirmed users older than 14 days...'

    result = self.find_unlinked_unconfirmed_users(14)
    unused_unconfirmed_users = result[:unused]

    if unused_unconfirmed_users.empty?
      puts 'No unused unconfirmed users to delete.'
      return
    end

    puts "Found #{unused_unconfirmed_users.count} unused unconfirmed users to delete."

    # Delete in batches to avoid potential issues with large numbers
    deleted_count = 0

    # Actually delete the users
    unused_unconfirmed_users.each_slice(100) do |batch|
      User.where(id: batch).destroy_all
      deleted_count += batch.count
      puts "Deleted #{deleted_count} users so far..."
    end

    puts "Successfully deleted #{unused_unconfirmed_users.count} unused unconfirmed users."
  end
end