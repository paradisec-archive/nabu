set :application, 'nabu'
set :repository,  'git@github.com:nabu-catalog/nabu'

set :scm, :git

role :web, '115.146.93.26'
role :app, '115.146.93.26'
role :db,  '115.146.93.26', :primary => true # This is where Rails migrations will run

set :deploy_to, "/srv/www/#{application}"

set :user, 'deploy'
set :use_sudo, false

set :deploy_via, :remote_cache

set :ssh_options, {
  :forward_agent => true,
  :port          => 22,
  :paranoid      => false
}

set :default_shell, "/bin/bash --login"

namespace :sunspot do
  task :symlink, :except => { :no_release => true } do
    rails_env = fetch(:rails_env, 'production')
    run "ln -nfs #{shared_path}/solr/data #{release_path}/solr/data"
    run "ln -nfs #{shared_path}/solr/pids #{release_path}/solr/pids"
  end

  desc 'Start solr'
  task :start do
    run "cd #{deploy_to}/current && /usr/bin/env rake sunspot:solr:start RAILS_ENV=production"
  end

  desc 'Stop solr'
  task :stop do
    run "cd #{deploy_to}/current && /usr/bin/env rake sunspot:solr:stop RAILS_ENV=production || true"
  end

  desc 'Restart solr'
  task :restart do
    stop
    start
  end

end

# Install after hooks for deployment.
after "deploy:symlink", "sunspot:symlink"
after "deploy:restart", "sunspot:restart"

require 'bundler/capistrano'
require 'capistrano-unicorn'
