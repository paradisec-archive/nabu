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

Importing old PARADISEC data:
 rake import:all

Running solr:
 rake sunspot:solr:start

After import:
 rake sunspot:reindex

Running the app:
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

upload DB:
 mysqldump -u root nabu_devel | gzip > nabu.sql.gz
 scp nabu.sql.gz deploy@115.146.93.26:
 ssh deploy@115.146.93.26
 gzip -dc nabu.sql.gz | mysql -u root nabu
 cd /srv/www/nabu/current
 RAILS_ENV=production rake sunspot:reindex


# OAI-PMH

OLAC available at:
 http://catalog.paradisec.org.au/oai/item

RIF-CS available ta:
  http://catalog.paradisec.org.au/oai/catalog

testing:
  install localtunnel to port forward your local webserver
  http://progrium.com/localtunnel/
  $ gem install localtunnel
  $ rbenv rehash
  $ localtunnel 3000
  use resulting server on OAI repository explorer:
  http://re.cs.uct.ac.za/

