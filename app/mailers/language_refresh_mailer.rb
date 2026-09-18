class LanguageRefreshMailer < ApplicationMailer
  def report
    run = params[:run]
    rendering = LanguageRefresh::Report.new(run)
    @body = run.report

    rendering.attachments.each { |name, csv| attachments[name] = { mime_type: 'text/csv', content: csv } }

    mail(to: Rails.application.config_for(:language_refresh)[:recipients], subject: rendering.subject)
  end
end
