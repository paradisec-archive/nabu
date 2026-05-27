class AnnotationReminderMailer < ApplicationMailer
  def daily_digest(user, essences)
    @user = user
    @items_with_unmapped = essences.group_by(&:item).sort_by { |item, _| item.identifier }.to_h

    mail(to: user.email,
         subject: 'Nabu: transcripts awaiting annotation mappings')
  end
end
