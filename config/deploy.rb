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
    :port => 22,
    :paranoid => false
}

set :default_shell, "/bin/bash --login"


require 'bundler/capistrano'
require 'capistrano-unicorn'
