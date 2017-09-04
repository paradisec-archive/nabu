class BulkEditReportMailer < ActionMailer::Base
  default :from => 'no-reply@paradisec.org.au', :to => 'admin@paradisec.org.au'

  def bulk_edit_report_email(email, failed_items, items_count, start_time)
    @email = email
    @failed_items = failed_items
    @items_count = items_count
    @start_time = start_time

    mail(to: email, subject: "Bulk item update made on #{start_time.strftime('%a %d/%m/%Y %T')} has been completed")
  end
end
