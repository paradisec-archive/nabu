class User < ActiveRecord::Base
  nilify_blanks
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable

  # Optionally a user has transferred their rights to another one, e.g. then deceased.
  belongs_to :rights_transferred_to, :class_name => 'User'

  attr_accessible :email, :first_name, :last_name, :address, :address2, :country, :phone, :password, :password_confirmation, :remember_me, :party_identifier
  attr_accessible :email, :first_name, :last_name, :address, :address2, :country, :phone, :password, :password_confirmation, :remember_me, :rights_transferred_to_id, :rights_transfer_reason, :admin, :contact_only, :party_identifier, :as => :admin
  attr_accessible :first_name, :last_name, :password, :password_confirmation, :contact_only, :party_identifier, :as => :contact_only

  validates :first_name, :presence => true
  validates :email, :presence => true, :unless => proc { |user| user.contact_only? }

  paginates_per 10

  scope :alpha, order(:first_name, :last_name)

  has_many :collection_admins
  has_many :collections, :through => :collection_admins, :dependent => :destroy

  has_many :item_admins
  has_many :items, :through => :item_admins, :dependent => :destroy

  has_many :item_agents, :dependent => :restrict

  delegate :name, :to => :rights_transferred_to, :prefix => true, :allow_nil => true

  scope :users, where(:contact_only => false)
  scope :contacts, where(:contact_only => true)
  scope :admins, where(:admin => true)
  scope :all_users

  def self.sortable_columns
    %w{last_name first_name id address adress2 country email phone admin contact_only}
  end

  def name
    "#{first_name} #{last_name}"
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
end
