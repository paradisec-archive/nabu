class ApplicationMailer < ActionMailer::Base
  default from: 'admin@paradisec.org.au', to: 'admin@paradisec.org.au'
  layout 'mailer'
end
