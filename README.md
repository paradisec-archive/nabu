Nabu Catalog
====


# Ruby help

plugins/gems/bundles:

    $ gem -v
    $ bundle update
    $ bundle install

Installing ruby:

    $ rbenv install [TAB][TAB]
    $ rbenv install 1.9.3-XXX
    $ rbenv global 1.9.3-XXX
    $ gem install bundler --no-ri --no-rdoc

DB setup:

    $ rake db:drop
    $ rake db:create
    $ rake db:migrate

Importing old PARADISEC data:

    $ rake import:all

Running solr:

    $ rake sunspot:solr:start

After import:

    $ rake sunspot:reindex

Running the app:

    $ script/rails s

test:

    $ rake cucumber:wip
    $ bundle exec cucumber --profile wip
    $ rake cucumber:ok
    $ bundle exec cucumber features/xxx

DB load:

    $ rake db:schema:load
    $ APP_ENV=test rake db:schema:load

after commit local to roll out to user acceptance testing server:

    $ cap uat deploy
    $ cap -T

roll out to production server:

    $ cap staging deploy
    $ cap production deploy

if necessary:

    $ cap production deploy:migrate

upload DB: (devcatalog.paradisec.org.au, or catalog.paradisec.org.au)

    $ mysqldump -u root nabu_devel | gzip > nabu.sql.gz
    $ scp nabu.sql.gz deploy@115.146.93.26:
    $ ssh deploy@115.146.93.26
    $ gzip -dc nabu.sql.gz | mysql -u root nabu
    $ cd /srv/www/nabu/current
    $ RAILS_ENV=uat rake sunspot:reindex

import archive files:

    $ RAILS_ENV=staging rake archive:update_files


# OAI-PMH

OLAC available at:
  * http://catalog.paradisec.org.au/oai/item

The feed that OLAC harvests:
  * http://catalog.paradisec.org.au/oai/item?verb=ListRecords&metadataPrefix=olac

RIF-CS available at:
  * http://catalog.paradisec.org.au/oai/collection

testing:
  * install localtunnel to port forward your local webserver
  * http://progrium.com/localtunnel/

    $ gem install localtunnel
    $ rbenv rehash
    $ localtunnel 3000

  use resulting server on an OAI repository explorer:
  * http://www.language-archives.org/register/register.php (OLAC)
  * http://re.cs.uct.ac.za/
  * http://oval.base-search.net/ (OAI-PMH validator)
  * http://validator.oaipmh.com/ (OAI-PMH validator)
  * http://repox.gulbenkian.pt/repox/jsp/testOAI-PMH.jsp (test protocol)

  URLs to test:
  * http://localhost:3000/oai/collection?verb=Identify
  * http://localhost:3000/oai/collection?verb=ListMetadataFormats
  * http://localhost:3000/oai/collection?verb=ListSets
  * http://localhost:3000/oai/collection?verb=ListIdentifiers
  * http://localhost:3000/oai/collection?verb=ListRecords

The feed that ANDS harvests:
  * http://catalog.paradisec.org.au/oai/collection?verb=ListRecords&metadataPrefix=rif

Test at ANDS:
  * https://demo.ands.org.au/registry/orca/admin/data_source_view.php?data_source_key=paradisec.org.au

Feed for a single collection:
  * http://catalog.paradisec.org.au/oai/collection?verb=GetRecord&metadataPrefix=rif&identifier=oai:paradisec.org.au:AA2
