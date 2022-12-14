# config valid for current version and patch releases of Capistrano
lock "~> 3.17.1"

set :application, "nabu"
set :repo_url, "git@github.com:nabu-catalog/nabu"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, -> { "/srv/www/#{fetch :application}" }

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# append :linked_files, "config/database.yml", 'config/master.key'

# Default value for linked_dirs is []
# append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/webpacker", "public/system", "vendor", "storage"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

# rbenv
# set :rbenv_type, :user # or :system, or :fullstaq (for Fullstaq Ruby), depends on your rbenv setup
# set :rbenv_ruby, File.read('.ruby-version').strip

# Bundler
append :linked_dirs, '.bundle'

# Rails
append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', '.bundle', 'public/system', 'public/uploads'
append :linked_files, 'config/database.yml', 'config/secrets.yml'
set :migration_role, :app

# Rollbar
set :rollbar_token, ENV['ROLLBAR_ACCESS_TOKEN']
# set :rollbar_env, Proc.new { fetch :stage }
# set :rollbar_role, Proc.new { :app }

# namespace :deploy do
#   task :shared_config_symlink, :except => { :no_release => true } do
#     run "ln -nfs #{shared_path}/config #{release_path}/config/shared"
#     run "ln -nfs #{shared_path}/config/config.yml #{release_path}/config/config.yml"
#   end
#   after 'deploy:create_symlink', 'deploy:shared_config_symlink'
# end

# namespace :sunspot do
#   task :setup, :except => { :no_release => true } do
#     run "mkdir -p #{shared_path}/solr/data"
#   end
#   after 'deploy:setup', 'sunspot:setup'

#   task :symlink, :except => { :no_release => true } do
#     run "ln -nfs #{shared_path}/solr/data #{release_path}/solr/data"
#     run "ln -nfs #{shared_path}/pids #{release_path}/solr/pids"
#   end
#   after 'deploy:create_symlink', 'sunspot:symlink'

#   desc 'Start solr'
#   task :start do
#     run "cd #{deploy_to}/current && bundle exec rake sunspot:solr:start RAILS_ENV=#{rails_env}"
#   end

#   desc 'Stop solr'
#   task :stop do
#     run "cd #{deploy_to}/current && bundle exec rake sunspot:solr:stop RAILS_ENV=#{rails_env}; sleep 5; killall -9 java || true"
#   end

#   desc 'Reindex solr'
#   task :reindex do
#     run "cd #{deploy_to}/current && bundle exec rake sunspot:reindex RAILS_ENV=#{rails_env}"
#   end

#   desc 'Restart solr'
#   task :restart do
#     stop
#     start
#   end
# # Restarting Solr seems to cause all sorts of issues on Staging, so commented out
# #  after 'deploy:restart', 'sunspot:restart'
# end
