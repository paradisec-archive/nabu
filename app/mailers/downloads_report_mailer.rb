class DownloadsReportMailer < ApplicationMailer
  def downloads_email(user, results, date_from, date_to)
    @user = user
    @results = results
    @date_from = date_from
    @date_to = date_to

    mail(to: @user.email, subject: "[nabu] Depositors Downloads Report: #{@date_from.strftime('%e %b %Y')} to #{@date_to.strftime('%e %b %Y')} ")
  end
end
