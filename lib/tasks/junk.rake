namespace :junk do
  desc 'Junk task'
  task doit: :environment do
    env = ENV.fetch('AWS_PROFILE').sub('nabu-', '')

    junk = JunkService.new(env)
    junk.run
  end
end
