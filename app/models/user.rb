class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable

  attr_accessible :email, :first_name, :last_name, :address, :address2, :country, :phone, :password, :password_confirmation, :remember_me
  attr_accessible :email, :first_name, :last_name, :address, :address2, :country, :phone, :password, :password_confirmation, :remember_me, :admin, :operator, :as => :admin

  validates :first_name, :presence => true

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

  def time_zone
    'Sydney'
  end
end
