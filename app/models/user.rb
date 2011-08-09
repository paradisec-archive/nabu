class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable

  attr_accessible :email, :first_name, :last_name, :address, :country, :phone, :password, :password_confirmation, :remember_me
  attr_accessible :admin, :operator, :as => :admin

  validates :first_name, :presence => true
  validates :last_name, :presence => true

  def name
    "#{first_name} #{last_name}"
  end

  def admin?
    admin
  end
end
