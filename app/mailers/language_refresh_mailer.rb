class LanguageRefreshMailer < ApplicationMailer
  def report
    run = params[:run]
    report = LanguageRefresh::Report.new(run)
    @body = run.report.presence || report.body

    report.attachments.each { |name, csv| attachments[name] = { mime_type: 'text/csv', content: csv } }

    mail(to: Rails.application.config_for(:language_refresh)[:recipients], subject: report.subject)
  end
end
