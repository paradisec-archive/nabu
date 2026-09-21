class ApplicationMailer < ActionMailer::Base
  default from: Rails.configuration.mailer_from, to: 'admin@paradisec.org.au'
  layout 'mailer'
end
