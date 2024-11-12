# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require 'csv'

CSV.foreach('data/country_boundingboxes.csv', headers: true) do |row|
  country = Country.where(name: row['country']).first
  if country
    LatlonBoundary.create!(
      {
        west_limit: row['longmin'],
        north_limit: row['latmax'],
        east_limit: row['longmax'],
        south_limit: row['latmin'],
        country: country,
        wrapped: (row['Wrapped'] == 'WRAPPED') # don't know what to do with this value
      })
  end
end
