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

The application is designed to be deployed using an AWS code pipeline deployment into containers using CDK

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
nabu_run bundle exec cap production deploy --dry-run
nabu_run bundle exec cap production deploy
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
ssh deploy@catalog.paradisec.org.au "mysqldump -u root nabu | bzip2 > nabu.sql.gz"
scp deploy@catalog.paradisec.org.au:nabu.sql.bz2 .
bzip2 -dc nabu.bz2 | mysql -h 127.0.0.1 -u root nabu_devel
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

## Server Setup
```bash
# Ubuntu 22.04
# Ruby deps
apt install autoconf bison patch build-essential rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev
# gem deps
apt install libmagic-dev libmagickwand-dev default-mysql-server default-libmysqlclient-dev nginx libcurl4-openssl-dev
apt install certbot python3-certbot-nginx ffmpeg


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

nabu_run bundle exec cap production puma:install
nabu_run bundle exec cap production puma:generate_nginx_config_locally; scp nginx.conf server:

certbot
sudo apt install default-jdk -y
# https://www.vultr.com/docs/install-apache-solr-on-ubuntu-20-04/
/etc/default/solr.in.sh set SOLR_HOME to /srv/www/nabu/current/solr

#Fix the PDF policy in
vi /etc/ImageMagick-6/policy.xml
# COmment out   <policy domain="coder" rights="none" pattern="PDF" />

# COnfigure mysql backups
sudo apt install automysqlbackup
vi /etc/default/automysqlbackup
```

## Cron Jobs

There are a number of cronjobs that need to be running for the catalog to operate correctly

capistrano will automatically create the cronjobs usning whenever.

They are defined in config/schedule.rb

## Upgrades

We should regularly make suer we are running the latest versions of third-party packages

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
