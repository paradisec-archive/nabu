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
* db - mysql data base (dev + test)
* s3 - s3 mock

You can then easily run all the standard commands by prefixing with ***nabu***

``` bash
nabu_run bundle install
nabu_run bundle exec rake db:prepare
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

If ECR complains about access

```bash
ACCOUNT=$(AWS_PROFILE=nabu-stage aws sts get-caller-identity | jq -r .Account)
AWS_PROFILE=nabu-stage aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin $ACCOUNT.dkr.ecr.ap-southeast-2.amazonaws.com
```

## Deployment

Use CDK to deploy new code via docker as well as any infrastructure changes

``` bash
bin/release stage
bin/release prod
```

If necessary:

``` bash
bin/aws/ecs_rake app deploy:migrate
bin/aws/ecs_rake app searchkick:reindex
```

## Importing a production database into your development environment

``` bash
AWS_PROFILE=nabu-prod bin/aws/db_backup
mysql -h 127.0.0.1 -u root nabu_devel < ../schema.sql
pv ../data.sql | mysql -h 127.0.0.1 -u root nabu_devel
nabu_run bin/rails db:environment:set RAILS_ENV=development
nabu_run bin/rake db:migrate
nabu_run bin/rake searchkick:reindex:all
```

# New Ethnologue data

We use the following source locations

* <https://www.ethnologue.com/codes/>
* <https://iso639-3.sil.org/code_tables/download_tables>

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

* <http://catalog.paradisec.org.au/oai/item>

The feeds that OLAC harvests:

* <http://catalog.paradisec.org.au/oai/item?verb=ListRecords&metadataPrefix=olac>
* <http://catalog.paradisec.org.au/oai/item?verb=Identify> (Archive identification)
* <http://catalog.paradisec.org.au/oai/item?verb=ListMetadataFormats>
* <http://catalog.paradisec.org.au/oai/item?verb=ListIdentifiers&metadataPrefix=olac>

Individual item:

* <http://catalog.paradisec.org.au/oai/item?verb=GetRecord&identifier=oai:paradisec.org.au:AA1-002&metadataPrefix=olac>

RIF-CS available at:

* <http://catalog.paradisec.org.au/oai/collection>

  use resulting server on an OAI repository explorer:

* <http://www.language-archives.org/register/register.php> (OLAC)
* <http://re.cs.uct.ac.za/>
* <http://oval.base-search.net/> (OAI-PMH validator)
* <http://validator.oaipmh.com/> (OAI-PMH validator)
* <http://repox.gulbenkian.pt/repox/jsp/testOAI-PMH.jsp> (test protocol)

  URLs to test:

* [http://localhost:3000/oai/collection?verb=Identify
* [http://localhost:3000/oai/collection?verb=ListMetadataFormats
* [http://localhost:3000/oai/collection?verb=ListSets
* [http://localhost:3000/oai/collection?verb=ListIdentifiers
* <http://localhost:3000/oai/collection?verb=ListRecords>

The feed that ANDS harvests:

* <http://catalog.paradisec.org.au/oai/collection?verb=ListRecords&metadataPrefix=rif>

Test at ANDS:

* <https://demo.ands.org.au/registry/orca/admin/data_source_view.php?data_source_key=paradisec.org.au>

Feed for a single collection:

* <http://catalog.paradisec.org.au/oai/collection?verb=GetRecord&metadataPrefix=rif&identifier=oai:paradisec.org.au:AA2>

To validate our XML output as per OLAC

* Download <https://xerces.apache.org/mirrors.cgi#binary>
* Extract it

```bash
java -cp xercesImpl.jar:xercesSamples.jar sax.Counter -n -np -v -s -f item.xml
```

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

# node modules
nabu_run yarn upgrade-interactive

# New rails version
rails new nabu --database=mysql --javascript=esbuild --css=sass --skip-action-cable --skip-kamal
```
