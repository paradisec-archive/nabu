role :web, 'catalog.paradisec.org.au'
role :app, 'catalog.paradisec.org.au'
role :db,  'catalog.paradisec.org.au', :primary => true # This is where Rails migrations will run
set :rails_env, 'staging'
