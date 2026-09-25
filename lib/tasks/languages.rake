namespace :languages do
  desc 'Run the Language Refresh now: bring every Language into line with its Source and email the report'
  task refresh: :environment do
    run = LanguageRefreshService.new.run
    abort 'Another Language Refresh Run holds the lock' if run.nil?

    puts "Language Refresh Run #{run.id} #{run.status}"
  end
end
