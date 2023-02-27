# Use this file to easily define all of your cron jobs
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

job_type :nabu_rake,  "cd :path && if [ ! -f tmp/pids/disable_cron ]; then :environment_variable=:environment flock --nonblock --verbose tmp/locks/:lock.lock :bundle_command rake :task DRY_RUN=true --silent :output; fi"

every 1.day, :at => '12:00 am' do
  nabu_rake "archive:export_metadata VERBOSE=true", lock: 'archive_export_metadata'
end

every 1.day, :at => '12:00 am' do
  nabu_rake "archive:import_files VERBOSE=true", lock: 'archive_import_files'
end

# TODO: We really shouldn't need this, commenting out for now
# every 1.hour do
#   nabu_rake "sunspot:reindex", lock: 'sunsport_reindex', output: { error: 'log/reindex.error.log' }
# end

every 1.day, :at => '2:00 am' do
  nabu_rake "archive:mint_dois MINT_DOIS_BATCH_SIZE=500", lock: 'archive_mint_dois', output: 'log/doi_minting.log'
end

every 1.day, :at => '12:04 am' do
  nabu_rake "archive:transform_images IMAGE_TRANSFORMER_BATCH_SIZE=2500", lock: 'archive_transform_images'
end

every 1.day, :at => '2:30 am' do
  nabu_rake "data:check_all_checksums", lock: 'data_check_all_checksums'
end

# jonog - perform daily database backups of the database and archive weekly backups for the rest of the month
#every 1.day, :at => '12:05 am' do
  # 0 5 * * * /home/deploy/scripts/backup-mysql.rb > /home/deploy/logging/backup-`date +\%F`.log
#end
