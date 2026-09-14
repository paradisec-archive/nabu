class DeleteUnconfirmedUsersJob < ApplicationJob
  queue_as :maintenance

  AGE = 14.days

  REFERENCES = [
    [Collection, :collector_id],
    [Collection, :operator_id],
    [Item, :collector_id],
    [Item, :operator_id],
    [ItemAgent, :user_id],
    [Permission, :user_id],
    [Comment, :owner_id],
    [User, :rights_transferred_to_id],
    [Download, :user_id],
    [Essence, :created_by_id]
  ].freeze

  def perform
    users = unreferenced_unconfirmed_users
    logger.info("Found #{users.size} unconfirmed users older than #{AGE.inspect} that are not referenced anywhere")

    return if users.empty?

    User.transaction { users.each(&:destroy!) }
    logger.info("Deleted #{users.size} unconfirmed users")

    deleted = users.map { |user| user_details(user) }
    AdminMailer.with(report_data: { total_deleted: deleted.size, deleted_users: deleted }).unconfirmed_users_deleted_report.deliver_now
  end

  private

  def unreferenced_unconfirmed_users
    candidates = User.unconfirmed(older_than: AGE).to_a
    ids = candidates.map(&:id)
    referenced = REFERENCES.flat_map { |model, column| model.where(column => ids).distinct.pluck(column) }.to_set

    candidates.reject { |user| referenced.include?(user.id) }
  end

  def user_details(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      created_at: user.created_at,
      created_days_ago: ((Time.current - user.created_at) / 1.day).to_i
    }
  end
end
