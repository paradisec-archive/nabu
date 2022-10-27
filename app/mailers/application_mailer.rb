class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@paradisec.org.au', to: 'admin@paradisec.org.au'
  layout 'mailer'
end
