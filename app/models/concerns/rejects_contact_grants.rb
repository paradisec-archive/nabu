# Shared guard for the four permission grant models (collection/item read-only and edit grants).
# Contact-only users exist purely so that work can be attributed to them (collector/operator);
# they never log in, so they must never hold an access grant.
module RejectsContactGrants
  extend ActiveSupport::Concern

  included do
    validate :grantee_must_not_be_contact_only
  end

  private

  def grantee_must_not_be_contact_only
    return unless user&.contact_only?

    errors.add(:user, 'cannot be a contact-only user; contacts can be attributed but not granted access')
  end
end
