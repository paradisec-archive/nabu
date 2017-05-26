server '115.146.80.168', :app, :web, :db, :primary => true
set :user, 'ubuntu'

set :unicorn_env, 'staging'

set :branch, 'develop'