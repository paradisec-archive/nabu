role :web, '115.146.93.26'
role :app, '115.146.93.26'
role :db,  '115.146.93.26', :primary => true # This is where Rails migrations will run
set :rails_env, 'uat'
