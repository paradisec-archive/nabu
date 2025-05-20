class UnconfirmedUsersService
  attr_reader :unconfirmed_users, :referenced_users, :unreferenced_users, :age_days

  # Allow initializing with age criteria and a dry_run option
  def initialize(options = {})
    @age_days = options[:age_days] || 7
    @dry_run = options[:dry_run] || false
    @logger = options[:logger] || Rails.logger

    # Initialize storage for results
    @unconfirmed_users = []
    @referenced_users = []
    @unreferenced_users = []
    @report_data = {}
  end

  # Main method that executes the service's operations
  def prepare
    find_unconfirmed_users
    categorize_users
    generate_report

    @report_data
  end

  def self.deletion_report(options = {})
    puts 'Generating deletion candidate report for unconfirmed users...'

    service = new(age_days: 7)
    report_data = service.prepare

    puts "Total unconfirmed users (older than 14 days): #{report_data[:total]}"
    puts "Referenced unconfirmed users: #{report_data[:referenced_count]}"
    puts "Unreferenced unconfirmed users (to be deleted): #{report_data[:unreferenced_count]}"

    AdminMailer.with(report_data:).unconfirmed_users_deletion_report.deliver_now

    puts "Deletion candidate report email sent with #{report_data[:unreferenced_count]} users scheduled for deletion."
  end

  # Class method for actually deleting old users
  def self.delete_old_users(options = {})
    puts 'Deleting unused unconfirmed users older than 14 days...'

    service = new(age_days: 14)
    service.prepare

    report_data = service.delete_unreferenced_users

    deleted_count = report_data[:total_deleted] || 0
    failed_count = report_data[:total_failed] || 0

    puts "Found #{report_data[:unreferenced_count]} users eligible for deletion."

    if deleted_count > 0
      puts "Successfully deleted #{deleted_count} unused unconfirmed users."

      if failed_count > 0
        puts "Failed to delete #{failed_count} users due to errors."
      end

      AdminMailer.with(report_data:).unconfirmed_users_deleted_report.deliver_now

      puts 'Deletion confirmation email sent.'
    end
  end

  def delete_unreferenced_users
    return @report_data if @unreferenced_users.empty?

    @logger.info("Deleting #{@unreferenced_users.size} unreferenced users...")

    # Store the list of users that were successfully deleted
    deleted_users = []
    failed_users = []

    # Delete in batches
    @unreferenced_users.each_slice(100) do |batch|
      user_ids = batch.map { |user| user[:id] }

      begin
        # Find the actual user objects
        users = User.where(id: user_ids)

        # Keep track of how many we've actually deleted
        before_count = deleted_users.size

        # Delete the users
        users.find_each do |user|
          begin
            if user.destroy
              deleted_users << user_details(user)
            else
              failed_users << user_details(user).merge(errors: user.errors.full_messages)
            end
          rescue => e
            @logger.error("Error deleting user #{user.id}: #{e.message}")
            failed_users << user_details(user).merge(errors: [e.message])
          end
        end

        @logger.info("Deleted #{deleted_users.size - before_count} users in this batch")
      rescue => e
        @logger.error("Error in batch deletion: #{e.message}")
        user_ids.each do |id|
          begin
            user = User.find_by(id: id)
            if user
              failed_users << user_details(user).merge(errors: [e.message])
            end
          rescue => inner_e
            @logger.error("Error finding user #{id}: #{inner_e.message}")
          end
        end
      end
    end

    @logger.info("Successfully deleted #{deleted_users.size} users, failed to delete #{failed_users.size} users")

    # Update the report with deletion results
    @report_data[:deleted_users] = deleted_users
    @report_data[:failed_deletions] = failed_users
    @report_data[:total_deleted] = deleted_users.size
    @report_data[:total_failed] = failed_users.size

    @report_data
  end

  private

  def find_unconfirmed_users
    @logger.info("Finding unconfirmed users older than #{@age_days} days who aren't referenced anywhere...")

    cutoff_date = Time.now - @age_days.days

    @unconfirmed_users = User
      .where(contact_only: false, confirmed_at: nil)
      .where('created_at < ?', cutoff_date)
      .map { | user | user_details(user) }

    @logger.info("Found #{@unconfirmed_users.size} unconfirmed users")
  end


  def categorize_users
    referenced_ids = Set.new

    # Collection references
    referenced_ids.merge(Collection.pluck(:collector_id))
    referenced_ids.merge(Collection.where.not(operator_id: nil).pluck(:operator_id))
    referenced_ids.merge(CollectionAdmin.pluck(:user_id))

    # Item references
    referenced_ids.merge(Item.pluck(:collector_id))
    referenced_ids.merge(Item.where.not(operator_id: nil).pluck(:operator_id))
    referenced_ids.merge(ItemAdmin.pluck(:user_id))
    referenced_ids.merge(ItemAgent.pluck(:user_id))
    referenced_ids.merge(ItemUser.pluck(:user_id))

    # Comment references
    referenced_ids.merge(Comment.pluck(:owner_id))

    # User-related references
    referenced_ids.merge(User.where.not(rights_transferred_to_id: nil).pluck(:rights_transferred_to_id))

    # Download references
    referenced_ids.merge(Download.pluck(:user_id))

    # Categorize users
    @unconfirmed_users.each do |user|
      if referenced_ids.include?(user[:id])
        # For referenced users, add reference details
        user[:references] = find_references(user[:id])
        @referenced_users << user
      else
        @unreferenced_users << user
      end
    end

    @logger.info("Found #{@referenced_users.size} referenced and #{@unreferenced_users.size} unreferenced users")
  end

  def find_references(user_id)
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
    references << 'Rights transferred to' if User.where(rights_transferred_to_id: user_id).exists?
    references << 'Download' if Download.where(user_id: user_id).exists?
    references
  end

  def generate_report
    @report_data = {
      total: @unconfirmed_users.size,
      referenced_count: @referenced_users.size,
      unreferenced_count: @unreferenced_users.size,
      referenced: @referenced_users,
      unreferenced: @unreferenced_users,
      age_days: @age_days,
      report_date: Time.now
    }
  end


  # Helper method to format user details consistently
  def user_details(user)
    created_days_ago = ((Time.now - user.created_at) / 86400).to_i
    {
      id: user.id,
      name: user.name,
      email: user.email,
      created_at: user.created_at,
      created_days_ago: created_days_ago
    }
  end
end
