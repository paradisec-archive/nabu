Delayed::Worker::destroy_failed_jobs = false # Keep them around so we can inspect them
Delayed::Worker::logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log')) # Split out the logs
