# Use this file to easily define all of your cron jobs.

every 1.day, :at => '4:30 am' do
  rake "archive:mint_dois"
end
