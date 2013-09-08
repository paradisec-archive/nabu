# Nabu Catalog

## Ruby help

plugins/gems/bundles:

``` bash
gem -v
bundle update
bundle install
```

Installing ruby:

``` bash
rbenv install [TAB][TAB]
rbenv install 1.9.3-XXX
rbenv global 1.9.3-XXX
gem install bundler --no-ri --no-rdoc
```

DB setup:

``` bash
rake db:drop
rake db:create
rake db:migrate
```

Importing old PARADISEC data:

``` bash
rake import:all
```

Running solr:

``` bash
rake sunspot:solr:start
```

After import:

``` bash
rake sunspot:reindex
```

Running the app:

``` bash
script/rails s
```

test:

``` bash
guard
```

DB load:

``` bash
rake db:schema:load
APP_ENV=test rake db:schema:load
```

after commit local to roll out to user acceptance testing server:

``` bash
cap uat deploy
cap -T
```

roll out to production server:

``` bash
cap production deploy
```

if necessary:

``` bash
cap production deploy:migrate
cap production sunspot:reindex
```

upload DB: (devcatalog.paradisec.org.au, or catalog.paradisec.org.au)

``` bash
mysqldump -u root nabu_devel | gzip > nabu.sql.gz
scp nabu.sql.gz deploy@115.146.93.26:
ssh deploy@115.146.93.26
gzip -dc nabu.sql.gz | mysql -u root nabu
cd /srv/www/nabu/current
RAILS_ENV=uat rake sunspot:reindex
```

import archive files:

``` bash
RAILS_ENV=uat rake archive:update_files
```

check if all files that have been uploaded are ok:
``` bash
cd /srv/www/nabu/current
RAILS_ENV=production rake --trace archive:update_files > log/update_files.log
```

restart web server
``` bash
cap uat unicorn:stop
ps aux #kill any remaining unicorns
cap uat unicorn:start
```

# NEW Ethnologue data

Download the latest version of the following tables from

    http://www.ethnologue.com/codes/default.asp#downloading

* CountryCodes.tab
* LanguageIndex.tab

Copy them into the data directory, overwriting the existing files there.

Run the following rake tasks to import them (in this order):

    $ rake import:countries
    $ rake import:languages

All new countries will be added to the Nabu countries table.
The new language codes of type "L" will be added to the Nabu language table.
All mappings of language to countries will also be added to the countries_languages table.

# Retire Ethnologue data

Download the latest version of the retired codes from

    http://www-01.sil.org/iso639-3/download.asp#retiredDownloads

* iso-639-3_Retirements.tab

Copy it into the data directory, overwriting the existing file there.

Run the following rake task to import them:

    $ rake import:retired

All existing codes that are retired are marked as such, incl name change.
Where name changes occurred items in CollectionLanguage, ItemContentLanguage, ItemSubjectLanguage are updated with the replacement language code.
Where splits happened, a message is printed.

# OAI-PMH

OLAC available at:
  * http://catalog.paradisec.org.au/oai/item

The feeds that OLAC harvests:
  * http://catalog.paradisec.org.au/oai/item?verb=ListRecords&metadataPrefix=olac
  * http://catalog.paradisec.org.au/oai/item?verb=Identify (Archive identification)
  * http://catalog.paradisec.org.au/oai/item?verb=ListMetadataFormats
  * http://catalog.paradisec.org.au/oai/item?verb=ListIdentifiers&metadataPrefix=olac

Individual item:
  * http://catalog.paradisec.org.au/oai/item?verb=GetRecord&identifier=oai:paradisec.org.au:AA1-002&metadataPrefix=olac

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


## Setup Rollbar

You need to configure the rollbar API key to capture exceptions.

The first method is creating a file in the shared directory, which will be
symlinked by cap.

``` bash
echo ROLLBAR_API_KEY > /srv/www/nabu/shared/config/rollbar.txt
```

alternatively you can pass it in as an environment variable at server start up,
for example.

``` bash
rails server ROLLBAR_ACCESS_TOKEN=ROLLBAR_API_KEY
```
