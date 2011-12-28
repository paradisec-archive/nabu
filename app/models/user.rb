class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable

  attr_accessible :email, :first_name, :last_name, :address, :country, :phone, :password, :password_confirmation, :remember_me
  attr_accessible :email, :first_name, :last_name, :address, :country, :phone, :password, :password_confirmation, :remember_me, :pd_user_id, :pd_contact_id, :admin, :operator, :as => :admin

  validates :first_name, :presence => true
  validates :last_name, :presence => true

  paginates_per 10

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
end
