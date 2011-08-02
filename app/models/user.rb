class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable

  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation, :remember_me

  validates :first_name, :presence => true
  validates :last_name, :presence => true

  def name
    "#{first_name} #{last_name}"
  end
end
