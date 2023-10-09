# ## Schema Information
#
# Table name: `users`
#
# ### Columns
#
# Name                            | Type               | Attributes
# ------------------------------- | ------------------ | ---------------------------
# **`id`**                        | `bigint`           | `not null, primary key`
# **`address`**                   | `string(255)`      |
# **`address2`**                  | `string(255)`      |
# **`admin`**                     | `boolean`          | `default(FALSE), not null`
# **`collector`**                 | `boolean`          | `default(FALSE), not null`
# **`confirmation_sent_at`**      | `datetime`         |
# **`confirmation_token`**        | `string(255)`      |
# **`confirmed_at`**              | `datetime`         |
# **`contact_only`**              | `boolean`          | `default(FALSE)`
# **`country`**                   | `string(255)`      |
# **`current_sign_in_at`**        | `datetime`         |
# **`current_sign_in_ip`**        | `string(255)`      |
# **`email`**                     | `string(255)`      |
# **`encrypted_password`**        | `string(255)`      | `default(""), not null`
# **`failed_attempts`**           | `integer`          | `default(0)`
# **`first_name`**                | `string(255)`      | `not null`
# **`last_name`**                 | `string(255)`      |
# **`last_sign_in_at`**           | `datetime`         |
# **`last_sign_in_ip`**           | `string(255)`      |
# **`locked_at`**                 | `datetime`         |
# **`party_identifier`**          | `string(255)`      |
# **`phone`**                     | `string(255)`      |
# **`remember_created_at`**       | `datetime`         |
# **`reset_password_sent_at`**    | `datetime`         |
# **`reset_password_token`**      | `string(255)`      |
# **`rights_transfer_reason`**    | `string(255)`      |
# **`sign_in_count`**             | `integer`          | `default(0)`
# **`unconfirmed_email`**         | `string(255)`      |
# **`unlock_token`**              | `string(255)`      |
# **`created_at`**                | `datetime`         | `not null`
# **`updated_at`**                | `datetime`         | `not null`
# **`rights_transferred_to_id`**  | `integer`          |
#
# ### Indexes
#
# * `index_users_on_confirmation_token` (_unique_):
#     * **`confirmation_token`**
# * `index_users_on_email` (_unique_):
#     * **`email`**
# * `index_users_on_reset_password_token` (_unique_):
#     * **`reset_password_token`**
# * `index_users_on_rights_transferred_to_id`:
#     * **`rights_transferred_to_id`**
# * `index_users_on_unlock_token` (_unique_):
#     * **`unlock_token`**
#

class User < ApplicationRecord
  # Users may not want paper_trail storing a history of their account information, so don't have has_paper_trail

  nilify_blanks

  # Include default devise modules. Others available are:
  # :omniauthable, :timeoutable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable

  # Optionally a user has transferred their rights to another one, e.g. then deceased.
  belongs_to :rights_transferred_to, :class_name => 'User', :optional => true

  validates :first_name, :presence => true
  validates :email, :presence => true, :unless => proc { |user| user.contact_only? }

  paginates_per 10

  scope :alpha, -> { order(:first_name, :last_name) }

  has_many :party_identifiers
  accepts_nested_attributes_for :party_identifiers, allow_destroy: true

  has_many :collection_admins
  has_many :collections, :through => :collection_admins, :dependent => :destroy

  has_many :item_admins
  has_many :items, :through => :item_admins, :dependent => :destroy

  has_many :item_users

  has_many :item_agents, :dependent => :destroy

  has_many :owned_items, :class_name => 'Item', :foreign_key => :collector_id, :dependent => :restrict_with_exception
  has_many :owned_collections, :class_name => 'Collection', :foreign_key => :collector_id

  delegate :name, :to => :rights_transferred_to, :prefix => true, :allow_nil => true

  has_many :access_grants,
           class_name: 'Doorkeeper::AccessGrant',
           foreign_key: :resource_owner_id,
           dependent: :delete_all

  has_many :access_tokens,
           class_name: 'Doorkeeper::AccessToken',
           foreign_key: :resource_owner_id,
           dependent: :delete_all

  # find all users with multiple entries by name
  scope :all_duplicates, -> { distinct.select([:first_name, :last_name]).group(:first_name, :last_name).having('count(*) > 1') }

  # find identifying info for single user with duplicates
  scope :duplicates_of, ->(first, last, user_ids = nil) {
    specific_user_ids = user_ids || [-1]
    User.joins('''left outer join (select first_name, last_name from users group by first_name, last_name having count(*) > 1) d
            on users.first_name = d.first_name and users.last_name = d.last_name''')
      .where('(users.first_name = ? and users.last_name = ?) or users.id in (?)', first, last, specific_user_ids)
  }

  scope :users, -> { where(:contact_only => false) }
  scope :collectors, -> { where(:collector => true) }
  scope :contacts, -> { where(:contact_only => true) }
  scope :admins, -> { where(:admin => true) }

  # Set random password for contacts
  before_validation do
    if self.contact_only?
      password = Devise.friendly_token.first(12)
      self.password = password
      self.password_confirmation = password
    end
  end

  def self.sortable_columns
    %w{last_name first_name id address address2 country email phone admin contact_only}
  end

  def name
    "#{first_name} #{last_name}"
  end

  def sortname
    "#{last_name} #{first_name}"
  end

  def display_label
    "#{name}#{!contact_only? ? ' <em>[user]</em>' : ''}"
  end

  def identifiable_name
    "#{id} - #{first_name} #{last_name} - #{email || '<no email>'}"
  end

  def admin?
    admin
  end

  def admin!
    self.admin = true
    save!
  end

  def time_zone
    'Sydney'
  end

  # Don't require email address for user
  def email_required?
    false
  end

  # Stop devise from sending emails for users without email
  def active_for_authentication?
    super && !(email.blank? && unconfirmed_email.blank?)
  end

  def full_path
    # FIX ME
    "http://catalog.paradisec.org.au/admin/users/#{id}"
  end

  def xml_key
    "paradisec.org.au/user/#{id}"
  end

  def destroy
    ok_to_destroy? ? super : self
  end

  def self.ransackable_attributes(_ = nil)
    %w[
      address address2 admin collector confirmation_sent_at confirmation_token confirmed_at
      contact_only country created_at current_sign_in_at current_sign_in_ip email encrypted_password
      failed_attempts first_name id last_name last_sign_in_at last_sign_in_ip locked_at party_identifier
      phone remember_created_at reset_password_sent_at reset_password_token rights_transfer_reason
      rights_transferred_to_id sign_in_count unconfirmed_email unlock_token updated_at
    ]
  end

  private

  def ok_to_destroy?
    errors.clear
    errors.add(:base, 'User owns items and cannot be removed.') if owned_items.positive?
    errors.empty?
  end

  protected

  # Don't send email for contacts
  def confirmation_required?
    !confirmed? && !self.contact_only?
  end
end
