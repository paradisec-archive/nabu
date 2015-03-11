# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

require 'csv'

CSV.foreach('db/country_boundingboxes.csv', headers: true) do |row|
  country = Country.where(name: row['country']).first
  if country
    LatlonBoundary.create!(
      {
        west_limit: row['longmin'],
        north_limit: row['latmax'],
        east_limit:row['longmax'],
        south_limit: row['latmin'],
        country: country,
        wrapped: (row['Wrapped'] == 'WRAPPED') # don't know what to do with this value
      })
  end
end