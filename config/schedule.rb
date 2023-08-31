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

job_type :nabu_rake,  "cd :path && if [ ! -f tmp/pids/disable_cron ]; then :environment_variable=:environment flock --nonblock tmp/locks/:lock.lock :bundle_command rake :task --silent :output; fi"
job_type :nabu,  "cd :path && :environment_variable=:environment :bundle_command :task"

every 1.day, :at => '12:00 am' do
  nabu_rake "archive:export_metadata VERBOSE=true", lock: 'archive_export_metadata'
end

every 1.hour do
  nabu_rake "archive:import_files VERBOSE=true", lock: 'archive_import_files'
end

every 1.day, :at => '2:00 am' do
  nabu_rake "archive:mint_dois MINT_DOIS_BATCH_SIZE=500", lock: 'archive_mint_dois', output: 'log/doi_minting.log'
end

every 1.day, :at => '12:04 am' do
  nabu_rake "archive:transform_images IMAGE_TRANSFORMER_BATCH_SIZE=2500", lock: 'archive_transform_images'
end

# No checksums during migration so as not to break the QCIF cache
# every 1.day, :at => '2:30 am' do
#   nabu_rake "data:check_all_checksums", lock: 'data_check_all_checksums'
# end
