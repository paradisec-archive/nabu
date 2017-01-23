# == Schema Information
#
# Table name: users
#
#  id                       :integer          not null, primary key
#  email                    :string(255)
#  encrypted_password       :string(255)      default(""), not null
#  reset_password_token     :string(255)
#  reset_password_sent_at   :datetime
#  remember_created_at      :datetime
#  sign_in_count            :integer          default(0)
#  current_sign_in_at       :datetime
#  last_sign_in_at          :datetime
#  current_sign_in_ip       :string(255)
#  last_sign_in_ip          :string(255)
#  password_salt            :string(255)
#  confirmation_token       :string(255)
#  confirmed_at             :datetime
#  confirmation_sent_at     :datetime
#  unconfirmed_email        :string(255)
#  failed_attempts          :integer          default(0)
#  unlock_token             :string(255)
#  locked_at                :datetime
#  first_name               :string(255)      not null
#  last_name                :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  admin                    :boolean          default(FALSE), not null
#  address                  :string(255)
#  address2                 :string(255)
#  country                  :string(255)
#  phone                    :string(255)
#  contact_only             :boolean          default(FALSE)
#  rights_transferred_to_id :integer
#  rights_transfer_reason   :string(255)
#  party_identifier         :string(255)
#

class User < ActiveRecord::Base
  # Users may not want paper_trail storing a history of their account information, so don't have has_paper_trail

  nilify_blanks
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable

  # Optionally a user has transferred their rights to another one, e.g. then deceased.
  belongs_to :rights_transferred_to, :class_name => 'User'

  attr_accessible :email, :first_name, :last_name, :address, :address2, :country, :phone, :password, :password_confirmation, :remember_me, :party_identifier, :collector
  attr_accessible :email, :first_name, :last_name, :address, :address2, :country, :phone, :password, :password_confirmation, :remember_me, :unconfirmed_email, :rights_transferred_to_id, :rights_transfer_reason, :admin, :contact_only, :party_identifier, :collector, :as => :admin
  attr_accessible :first_name, :last_name, :password, :password_confirmation, :contact_only, :party_identifier, :collector, :as => :contact_only

  validates :first_name, :presence => true
  validates :email, :presence => true, :unless => proc { |user| user.contact_only? }

  paginates_per 10

  scope :alpha, order(:first_name, :last_name)

  has_many :collection_admins
  has_many :collections, :through => :collection_admins, :dependent => :destroy

  has_many :item_admins
  has_many :items, :through => :item_admins, :dependent => :destroy

  has_many :item_users

  has_many :item_agents, :dependent => :destroy

  has_many :owned_items, :class_name => 'Item', :foreign_key => :collector_id, :dependent => :restrict

  delegate :name, :to => :rights_transferred_to, :prefix => true, :allow_nil => true

  # find all users with multiple entries by name
  scope :all_duplicates, select([:first_name, :last_name]).group(:first_name, :last_name).having('count(*) > 1')

  # find identifying info for single user with duplicates
  scope :duplicates_of, ->(first, last, user_ids = nil) {
    specific_user_ids = user_ids || [-1]
    User.joins('''left outer join (select first_name, last_name from users group by first_name, last_name having count(*) > 1) d
            on users.first_name = d.first_name and users.last_name = d.last_name''')
      .where('(users.first_name = ? and users.last_name = ?) or users.id in (?)', first, last, specific_user_ids)
  }

  scope :users, where(:contact_only => false)
  scope :collectors, where(:collector => true)
  scope :contacts, where(:contact_only => true)
  scope :admins, where(:admin => true)
  scope :all_users

  # Set random password for contacts
  before_validation do
    return unless self.contact_only?
    password = Devise.friendly_token.first(12)
    self.password = password
    self.password_confirmation = password
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

  private

  def ok_to_destroy?
    errors.clear
    errors.add(:base, "User owns items and cannot be removed.") if owned_items.count > 0
    errors.empty?
  end

  protected

  # Don't send email for contacts
  def confirmation_required?
    !confirmed? && !self.contact_only?
  end
end
