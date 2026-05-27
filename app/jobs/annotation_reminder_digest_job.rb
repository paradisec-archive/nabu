class AnnotationReminderDigestJob < ApplicationJob
  queue_as :default

  WINDOW = 7.days

  def perform
    extension_match = Essence::ANNOTATION_EXTENSIONS
                      .map { |ext| Essence.arel_table[:filename].matches("%.#{ext}") }
                      .reduce(:or)

    grouped = Essence
              .where(created_at: WINDOW.ago..)
              .where.not(created_by_id: nil)
              .where(extension_match)
              .left_joins(:outgoing_annotation_links)
              .where(essence_annotations: { id: nil })
              .includes(item: :collection)
              .group_by(&:created_by_id)

    users_by_id = User.where(id: grouped.keys).index_by(&:id)

    grouped.each do |user_id, essences|
      user = users_by_id[user_id]
      next if user.nil? || user.email.blank?

      AnnotationReminderMailer.daily_digest(user, essences).deliver_later
    end
  end
end
