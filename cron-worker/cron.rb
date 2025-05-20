#!/usr/bin/env ruby

require 'rufus-scheduler'
require 'aws-sdk-ses'
require 'stringio'

require File.expand_path('../config/environment', __dir__) # adjust the path as necessary

Rake::Task.clear # necessary to avoid duplicate tasks
Nabu::Application.load_tasks

ses = Aws::SES::Client.new(region: 'ap-southeast-2')

scheduler = Rufus::Scheduler.new

scheduler.cron '27 4 * * tue'  do
  name = 'Check DB S3 Sync'
  task = 'catalog:check_db_s3_sync'

  puts "#{Time.current}: Starting task #{name}"

  begin
    Rake::Task[task].invoke
  ensure
    Rake::Task[task].reenable
  end
end

scheduler.cron '27 5 * * tue'  do
  name = 'Check Replication'
  task = 'catalog:check_replication'

  puts "#{Time.current}: Starting task #{name}"

  begin
    Rake::Task[task].invoke
  ensure
    Rake::Task[task].reenable
  end
end

scheduler.cron '27 5 * * wed'  do
  name = 'Unconfirmed User Deletion Report'
  task = 'users:list_deletion_candidates'

  puts "#{Time.current}: Starting task #{name}"

  begin
    Rake::Task[task].invoke
  ensure
    Rake::Task[task].reenable
  end
end

scheduler.cron '27 5 * * wed'  do
  name = 'Delete unconfirmed users'
  task = 'users:delete_unconfirmed'

  puts "#{Time.current}: Starting task #{name}"

  begin
    Rake::Task[task].invoke
  ensure
    Rake::Task[task].reenable
  end
end

scheduler.cron '10 1 * * *'  do
  name = 'Mint Dois'
  task = 'catalog:mint_dois'

  puts "#{Time.current}: Starting task #{name}"

  output = StringIO.new
  $stdout = output
  $stderr = output

  begin
    Rake::Task[task].invoke
  ensure
    Rake::Task[task].reenable
    $stdout = STDOUT # Reset stdout to its original value
    $stderr = STDERR # Reset stderr to its original value
  end

  email_output = output.string
  puts email_output

  if email_output.size < 5
    puts 'No output from task, not sending email.'

    next
  end

  params = {
    source: 'admin@paradisec.org.au',
    destination: {
      to_addresses: ['admin@paradisec.org.au', 'johnf@inodes.org', 'jferlito@gmail.com']
    },
    message: {
      subject: {
        data: "Paradisec Scheduled Job - #{name}"
      },
      body: {
        text: {
          data: "The job had the following output:\n\n#{email_output}"
        }
      }
    }
  }

  begin
    ses.send_email(params)
    puts "Email sent with task output. #{email_output}"
  rescue Aws::SES::Errors::ServiceError => e
    puts "Email failed to send: #{e}"
  end

  puts "#{Time.current}: Finished task #{name}"
end

scheduler.join
