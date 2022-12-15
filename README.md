# Nabu Catalog

## Setting up your dev environment

This application has been configured around docker-compose

```bash
# Build the base image
docker-compose build

# Bring up all the containers
docker-compose up
```

This brings up the following containers
* app - the rails app
* search - Solr instance for search (dev + test)
* db - mysql data base (dev + test)

You should set the following alias to exec commands easily inside the container

```bash
alias nabu="docker-compose exec app"
alias nabu_test="docker-compose exec -e RAILS_ENV=test app"
```

You can then easily run all the standard commands by prefixing with ***nabu***

``` bash
nabu_run bundle install
nabu bundle exec rake db:create
nabu bundle exec rake db:schema:load
nabu_test bundle exec rake db:schema:load
nabu_run bundle exec guard # Test runner
```


## Production

The application is designed to be deployed using an AWS code pipeline deployment into containers using CKD

To bootstrap a new account

```bash
# Setup an AWS account and credentials as per your preferred method and set the environment to use it
AWS_PROFILE=nabu
REGION=ap-southeast-2
ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
cdk bootstrap aws://$ACCOUNT/$REGION
```

```bash
taskName=DbMigrate|Reindex
task=$(aws ecs list-task-definitions | jq  -r '.taskDefinitionArns | .[]' | grep $taskName); echo $task
cluster=$(aws ecs list-clusters | jq -r '.clusterArns | .[]'); echo $cluster
aws ecs run-task --cluster $cluster --task-definition $task
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

Note: if you update the Solr configuration (in staging), you will need to run a script on the server to copy over the new config, and restart and reindex Solr.
Run the below from the home directory on the server.

``` bash
./scripts/fix_solr.sh
```

## Importing a production database into your development environment

``` bash
ssh deploy@catalog.paradisec.org.au "mysqldump -u root nabu | gzip > nabu.sql.gz"
scp deploy@catalog.paradisec.org.au:nabu.sql.gz .
gzip -dc nabu.sql.gz | mysql -u root nabu_devel
rake sunspot:reindex
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


## Setup Secrets

```bash
aws secretsmanager list-secrets

aws secretsmanager put-secret-value --secret-id ARN --secret-string "{\"site_key\":\"***\", \"secret_key\":\"***\"}"
```

## Server Setup
```bash
# Ubuntu 22.04
# Ruby deps
apt install autoconf bison patch build-essential rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev
# gem deps
apt install libmagic-dev libmagickwand-dev default-mysql-server default-libmysqlclient-dev

git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc
eval "$(~/.rbenv/bin/rbenv init - bash)"
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
rbenv install 3.1.3
rbenv global 3.1.3

# Setup the DB
sudo mysql -u root
CREATE USER 'nabu'@'localhost';
ALTER USER 'nabu'@'localhost' IDENTIFIED BY 'GENERATE A PW';
GRANT ALL PRIVILEGES ON nabu.* TO 'nabu'@'localhost';

nabu_run bundle exec cap staging puma:install
```
