class User < ActiveRecord::Base
  nilify_blanks
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable

  attr_accessible :email, :first_name, :last_name, :address, :address2, :country, :phone, :password, :password_confirmation, :remember_me
  attr_accessible :email, :first_name, :last_name, :address, :address2, :country, :phone, :password, :password_confirmation, :remember_me, :admin, :operator, :contact_only, :as => :admin

  validates :first_name, :presence => true
  validates :email, :presence => true, :unless => proc { |user| user.contact_only? }

  paginates_per 10

  scope :alpha, order(:first_name, :last_name)

  has_many :collection_admins
  has_many :collections, :through => :collection_admins, :dependent => :destroy

  has_many :item_admins
  has_many :items, :through => :item_admins, :dependent => :destroy

  has_many :item_agents, :dependent => :restrict

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
