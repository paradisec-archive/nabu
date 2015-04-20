class DownloadsReportMailer < ActionMailer::Base
  default :from => 'admin@paradisec.org.au', :to => 'admin@paradisec.org.au'

  def downloads_mail(collection)
    @user = collection.collector
    @collection = collection
    @downloads = collection.retrieve_annual_downloads

    mail(to: @user.email, subject: "[nabu] Downloads report for Collection: #{@collection.title}")
  end
end
