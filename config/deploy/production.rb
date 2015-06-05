server 'catalog.paradisec.org.au', :app, :web, :db, :primary => true
set :user, 'deploy'

set :unicorn_env, 'production'