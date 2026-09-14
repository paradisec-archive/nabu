#!/usr/bin/env ruby

require 'rufus-scheduler'

require File.expand_path('../config/environment', __dir__) # adjust the path as necessary

Rake::Task.clear # necessary to avoid duplicate tasks
Nabu::Application.load_tasks

scheduler = Rufus::Scheduler.new

# By default rufus-scheduler swallows job errors (it only dumps them to stderr),
# so cron failures never reach Sentry. Report them explicitly before falling back
# to the default logging behaviour.
def scheduler.on_error(job, error)
  Sentry.capture_exception(error, extra: { cron_job: job&.original.to_s }) if defined?(Sentry)
ensure
  super
end

scheduler.join
