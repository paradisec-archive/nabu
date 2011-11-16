# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

u = User.create :email => 'user@example.com',
            :first_name => 'User',
            :last_name => 'Doe',
            :password => 'password',
            :password_confirmation => 'password',
u.confirm!
u = User.create :email => 'admin@example.com',
            :first_name => 'Admin',
            :last_name => 'Doe',
            :password => 'password',
            :password_confirmation => 'password',
            :admin => true,
u.confirm!

Country.create :name => 'Australia'
Country.create :name => 'Germany'

University.create :name => 'University of Sydney'
University.create :name => 'University of New South Wales'

Language.create :code => 'ski', :name => 'Sika'
Language.create :code => 'mqy', :name => 'Manggarai'

FieldOfResearch.create :identifier => 420114, :name => 'Indonesian Languages'
