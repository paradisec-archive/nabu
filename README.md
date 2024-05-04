# Nabu Catalog

## Setting up your dev environment

Use direnv to add bin to your path
```bash
PATH_add bin
```

Bring up the environment

```bash
# Build the base image
docker compose build

# Install the gems
nabu_run bundle

# Bring up all the containers
docker compose up
```

This brings up the following containers
* app - the rails app
* search - Solr instance for search (dev + test)
* proxyist - S3 proxy
* db - mysql data base (dev + test)
* s3 - s3 mock

You can then easily run all the standard commands by prefixing with ***nabu***

``` bash
nabu_run bundle install
nabu_run bundle exec rake db:create
nabu_run bundle exec rake db:schema:load
nabu_test bundle exec rake db:schema:load
nabu_run bundle exec guard # Test runner
```

## Production

The application is designed to be deployed with containers into an AWS account using CDK

To bootstrap a new account

```bash
# Setup an AWS account and credentials as per your preferred method and set the environment to use it
AWS_PROFILE=nabu
REGION=ap-southeast-2
ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
cdk bootstrap aws://$ACCOUNT/$REGION
```

## Deployment

Use CDK to deploy new code via docker as well as any infrastructure changes

``` bash
cd cdk
cdk --profile nabu-stage diff nabu-appstack-stage
cdk --profile nabu-stage deploy nabu-appstack-stage
```

If necessary:

``` bash
bin/aws/ecs_rake deploy:migrate
bin/aws/ecs_rake searchkick:reindex
```

## Importing a production database into your development environment

``` bash
bin/aws/ecs_shell app -c 'mysqldump -u nabu -h "$NABU_DATABASE_HOSTNAME" --password "$NABU_DATABASE_PASSWORD" nabu | bzip2 | base64 > /tmp/nabu.sql.bz2'
bzip2 -dc ../nabu.sql.bz2 | mysql -h 127.0.0.1 -u root nabu_devel
nabu_run bundle exec rake searchkick:reindex
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


# New Ethnologue data

We use the following source locations
* https://www.ethnologue.com/codes/
* https://iso639-3.sil.org/code_tables/download_tables

Run the following rake task to import everything

``` bash
bundle exec rake import:ethnologue
```

This will
* Add new countries and update names
* Update country names
* Add new languages and update names (Only Living languages)
* Add mappings of language to countries
* All existing languages that are retired are marked as such, incl name change.
* Where name changes occurred items in CollectionLanguage, ItemContentLanguage, ItemSubjectLanguage are updated with the replacement language code.
* Where splits happened, a message is printed.

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


## Setup Secrets

```bash
aws secretsmanager list-secrets

aws secretsmanager put-secret-value --secret-id ARN --secret-string "{\"site_key\":\"***\", \"secret_key\":\"***\"}"
```

## Upgrades

We should regularly make sure we are running the latest versions of third-party packages

```bash
# Ruby gems
nabu_run bundle outdated
nabu_run bundle update

# npm
nabu_run bin/importmap audit
nabu_run bin/importmap outdated

# Sentry
# https://docs.sentry.io/platforms/javascript/install/cdn/
vi app/views/layouts/application.html.haml


```
