class CsvDownloadMailer < ActionMailer::Base
  default :from => 'no-reply@paradisec.org.au', :to => 'admin@paradisec.org.au'

  def csv_download_email(email, user_name, total, start_time, filename, path)
    @email = email
    @user_name = user_name
    @total = total
    @start_time = start_time
    @filename = filename
    
    attachments[@filename] = File.read(path)

    puts "Sending CSV download to #{@user_name} [#{@email}] with attachment #{@filename} containing #{@total} results"
    
    mail(to: email, subject: "Nabu - CSV export started on #{start_time.strftime('%a %e %b %Y %i:%M %P')} has been completed")
  end
end
