# Nabu Catalog



# Ruby help

plugins/gems/bundles:
 gem -v
 bundle update
 bundle install

rvm:
 ruby -v
 rvm list known
 rvm install ruby-xxx

DB setup:
 rake db:drop
 rake db:create
 rake db:migrate

Importing old PARADISEC data:
 rake import:all

running:
 script/rails

test:
 rake cucumber:wip
 bundle exec cucumber --profile wip
 rake cucumber:ok
 bundle exec cucumber features/xxx

DB load:
 rake db:schema:load
 APP_ENV=test rake db:schema:load

after commit local:
 cap deploy
 cap -T