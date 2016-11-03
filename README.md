# Nabu Catalog

## Setting up your dev environment

This application has been configured with *guard*, it will ensure

* Tests are run
* Solr is running for dev and test
* Development web server is started
* All of the above is restarted when you edit files

``` bash
bundle install
bundle exec spring rake db:create
bundle exec spring rake db:schema:load
RAILS_ENV=test bundle exec spring rake db:schema:load
bundle exec guard
```

## Deployment
We are using Capistrano for deployment.

``` bash
cap deploy
cap production deploy
```

Note about deployment: if you see a 'Permission denied(publickey)' error, try running `ssh-add -k` in terminal

if necessary:

``` bash
cap deploy:migrate
cap sunspot:reindex
```

## Importing a production database into your development environment

``` bash
ssh deploy@catalog.paradisec.org.au "mysqldump -u root nabu | gzip > nabu.sql.gz"
scp deploy@catalog.paradisec.org.au:nabu.sql.gz .
gzip -dc nabu.sql.gz | mysql -u root nabu_devel
spring rake sunspot:reindex
```

## Production Tasks

import archive files

``` bash
RAILS_ENV=production bundle exec rake archive:update_files
```

check if all files that have been uploaded are ok:
``` bash
cd /srv/www/nabu/current
RAILS_ENV=production bundle exec rake --trace archive:update_files > log/update_files.log
```

check if all *-CAT-PDSC_ADMIN.xml files exist and create if necessary:
``` bash
cd /srv/www/nabu/current
RAILS_ENV=production bundle exec rake --trace archive:admin_files > log/admin_files.log
```

delete a collection with all its items:
``` bash
cd /srv/www/nabu/current
RAILS_ENV=production bundle exec rake archive:delete_collection[PA1]


# NEW Ethnologue data

Download the latest version of the following tables from

    http://www.ethnologue.com/codes/default.asp#downloading

* CountryCodes.tab
* LanguageIndex.tab

Copy them into the data directory, overwriting the existing files there.

Run the following rake tasks to import them (in this order):

``` bash
bundle exec rake import:countries
bundle exec rake import:languages
```

All new countries will be added to the Nabu countries table.
The new language codes of type "L" will be added to the Nabu language table.
All mappings of language to countries will also be added to the countries_languages table.

# Retire Ethnologue data

Download the latest version of the retired codes from

    http://www-01.sil.org/iso639-3/download.asp#retiredDownloads

* iso-639-3_Retirements.tab

Copy it into the data directory, overwriting the existing file there.

Run the following rake task to import them:

``` bash
bundle exec rake import:retired
```

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

``` bash
gem install localtunnel
rbenv rehash
localtunnel 3000
```

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

Alternatively you can pass it in as an environment variable at server start up,
for example.

``` bash
rails server ROLLBAR_ACCESS_TOKEN=ROLLBAR_API_KEY
```
