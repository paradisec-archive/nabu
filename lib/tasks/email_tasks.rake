desc 'send downloads report mail'
task send_downloads_report_emails: :environment do
  reports_to_send = ScheduledReport.where(scheduled_for: DateTime.now.strftime('%d %B'))

  reports_to_send.each do |report|
    DownloadsReportMailer.downloads_mail(report.collection).deliver!
  end
end
