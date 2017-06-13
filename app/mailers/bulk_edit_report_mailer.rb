class BulkEditReportMailer < ActionMailer::Base
  default :from => 'admin@paradisec.org.au', :to => 'admin@paradisec.org.au'

  def bulk_edit_report_email(email, failed_items, items_count, start_time)
    @email = email
    @failed_items = failed_items
    @items_count = items_count
    @start_time = start_time

    mail(to: email, subject: "Bulk edit items made on #{start_time} has been completed")
  end
end
