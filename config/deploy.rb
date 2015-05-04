role :web, '144.6.225.96'
role :app, '144.6.225.96'
role :db,  '144.6.225.96', :primary => true # This is where Rails migrations will run

set :rails_env,   'production'
set :unicorn_env, 'production'
set :app_env,     'production'
set :application, 'nabu'
# This is pointing at my fork
set :repository,  'git@github.com:nabu-catalog/nabu'
set :branch, ENV['CAP_BRANCH'] || 'master'
set :scm, :git

set :deploy_to, "/srv/www/#{application}"
# The staging user is 'ubuntu', but the prod user is 'deploy'
set :user, 'ubuntu'
set :use_sudo, false
set :deploy_via, :remote_cache
set :keep_releases, 5

set :ssh_options, { :forward_agent => true, }

set :default_shell, '/bin/bash --login'

set :shared_children, fetch(:shared_children) + ['tmp/sockets']

namespace :deploy do
  task :shared_config_symlink, :except => { :no_release => true } do
    run "ln -nfs #{shared_path}/config #{release_path}/config/shared"
  end
  after 'deploy:create_symlink', 'deploy:shared_config_symlink'
end

namespace :sunspot do
  task :setup, :except => { :no_release => true } do
    run "mkdir -p #{shared_path}/solr/data"
  end
  after 'deploy:setup', 'sunspot:setup'

  task :symlink, :except => { :no_release => true } do
    run "ln -nfs #{shared_path}/solr/data #{release_path}/solr/data"
    run "ln -nfs #{shared_path}/pids #{release_path}/solr/pids"
  end
  after 'deploy:create_symlink', 'sunspot:symlink'

  desc 'Start solr'
  task :start do
    run "cd #{deploy_to}/current && bundle exec rake sunspot:solr:start RAILS_ENV=#{rails_env}"
  end

  desc 'Stop solr'
  task :stop do
    run "cd #{deploy_to}/current && bundle exec rake sunspot:solr:stop RAILS_ENV=#{rails_env}; sleep 5; killall -9 java || true"
  end

  desc 'Reindex solr'
  task :reindex do
    run "cd #{deploy_to}/current && bundle exec rake sunspot:reindex RAILS_ENV=#{rails_env}"
  end

  desc 'Restart solr'
  task :restart do
    stop
    start
  end
# Restarting Solr seems to cause all sorts of issues on Staging, so commented out
#  after 'deploy:restart', 'sunspot:restart'
end

namespace :monit do
  task :unmonitor do
    run "sudo /usr/bin/monit unmonitor all || true"
  end
  task :monitor do
    run "sudo /usr/bin/monit monitor all"
  end
  after 'deploy:restart', 'monit:monitor'
  before 'deploy:restart', 'monit:unmonitor'
end

task :notify_rollbar, :roles => :app do
  set :revision, `git log -n 1 --pretty=format:"%H"`
  set :local_user, `whoami`
  set :rollbar_token, capture("cat #{shared_path}/config/rollbar.txt")
  rails_env = fetch(:rails_env, 'production')
  run "curl https://api.rollbar.com/api/1/deploy/ -F access_token=#{rollbar_token} -F environment=#{rails_env} -F revision=#{revision} -F local_username=#{local_user} >/dev/null 2>&1", :once => true
end
after :deploy, 'notify_rollbar'

require 'bundler/capistrano'
require 'capistrano-unicorn'
