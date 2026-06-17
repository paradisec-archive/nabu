# Redirects every outbound email to a single catch-all mailbox.
#
# Staging may run against a verbatim clone of the production database (see
# bin/aws/db_sync), so messages could otherwise be addressed to real users.
# This interceptor guarantees that can never happen by rewriting the recipient
# on every message and dropping cc/bcc.
class StagingMailInterceptor
  CATCH_ALL = 'johnf@inodes.org'.freeze

  def self.delivering_email(message)
    message.to = [CATCH_ALL]
    message.cc = nil
    message.bcc = nil
  end
end
