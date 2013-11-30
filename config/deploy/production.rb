#role :web, 'catalog.paradisec.org.au'
#role :app, 'catalog.paradisec.org.au'
#role :db,  'catalog.paradisec.org.au', :primary => true # This is where Rails migrations will run

role :web, 'paradisec.intersect.org.au'
role :app, 'paradisec.intersect.org.au'
role :db,  'paradisec.intersect.org.au', :primary => true # This is where Rails migrations will run

set :rails_env,   'production'
set :unicorn_env, 'production'
set :app_env,     'production'
