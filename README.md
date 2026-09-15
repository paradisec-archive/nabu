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
* search - OpenSearch instance for search (dev + test), pinned to production's version
* db - mysql data base (dev + test)
* s3 - s3 mock

You can then easily run all the standard commands by prefixing with ***nabu***

``` bash
nabu_run bundle install
nabu_run bundle exec rake db:prepare
```

### Resetting the search data volume after the OpenSearch 2.19 pin

OpenSearch was previously `latest` (3.x) locally. A data volume written by 3.x can't be opened by 2.19, so reset it once
and reindex development data. This briefly breaks search specs in every other checkout, so stop other test runs first.

```bash
docker compose rm --stop --force search
docker volume rm nabu_search-data
docker compose up --detach search
nabu_run bin/rake searchkick:reindex:all
```

Test indices are recreated by the next `bin/test` run.

## Running tests

``` bash
nabu_run bin/test                          # the whole suite, in parallel
nabu_run bin/test spec/models/item_spec.rb # specific files or examples
nabu_run bin/test --only-failures          # what failed last time
```

`bin/test` prepares the test databases before running RSpec, so a fresh checkout or a branch switch needs no manual step.

With no arguments `bin/test` runs the suite across parallel workers with `parallel_tests`, each with its own databases, search indices and bucket
(e.g. `nabu_test_2`). It uses 4 workers, or every core on a GitHub Actions runner; set `PARALLEL_TEST_PROCESSORS` to change that.
Any argument runs plain RSpec in a single process.

Each linked git worktree gets its own test namespace: its own test databases, search indices and catalogue bucket
on the shared containers, named after the worktree (e.g. `nabu_test_<worktree>`). The main checkout keeps the plain `nabu_test` names.
Set `NABU_TEST_NAMESPACE` to choose a namespace explicitly, or to an empty string for the plain names.

## Checking your work

``` bash
nabu_run bin/ci
```

`bin/ci` runs rubocop, brakeman, bundle-audit and `bin/test`, reports each step's runtime and exits non-zero if any fails.
The steps live in `config/ci.rb`. GitHub Actions runs the same checks, with linting, security scanning and the tests as separate jobs.

## Pruning test namespaces

Namespaces outlive their worktrees. Run `bin/test_prune` on the host to list the test databases, search indices and catalogue buckets
that belong to no current worktree, then `bin/test_prune --delete` to drop them. The main checkout's names are never touched.
A namespace set by hand with `NABU_TEST_NAMESPACE` counts as orphaned unless it matches a current worktree's name.

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

`bin/aws/db_sync` dumps the production database to S3, restores it into your
local `nabu_devel`, and resets every user's password to `password`. See
`docs/runbooks/db-sync.md` for the full design (it can also overwrite staging).

``` bash
bin/aws/db_sync   # choose target 1) dev
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
nabu_run pnpm up -i

# New rails version
rails new nabu --database=mysql --javascript=esbuild --css=sass --skip-action-cable --skip-kamal
```
