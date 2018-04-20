class CsvDownloadMailer < ActionMailer::Base
  default :from => 'no-reply@paradisec.org.au', :to => 'admin@paradisec.org.au'

  def csv_download_email(email, total, start_time, filename, path)
    @email = email
    @total = total
    @start_time = start_time
    @filename = filename
    
    attachments[@filename] = File.read(path)
    
    mail(to: email, subject: "CSV export started on #{start_time.strftime('%a %d/%m/%Y %T')} has been completed")
  end
end
