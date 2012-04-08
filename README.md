# Nabu Catalog



# Ruby help

plugins/gems/bundles:
 gem -v
 bundle update
 bundle install

Installing ruby:
  rbenv install [TAB][TAB] 
  rbenv install 1.9.3-XXX
  rbenv global 1.9.3-XXX
  gem install bundler --no-ri --no-rdoc

DB setup:
 rake db:drop
 rake db:create
 rake db:migrate

Running solr:
 rake sunspot:solr:start

Importing old PARADISEC data:
 rake import:all

running:
 script/rails s

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