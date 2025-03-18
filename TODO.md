# TODO

* Do solidQ/activeJob errors get caught by sentry?

## AWS

* Move the ECS to app instead of ingress subnet (MAYBE test in stage first)

## API

We are using Doorkeeper to provide oauth tokens
These are for API access not to act on behalf of users
If we give tokens to more than paragest we need to rethink this

## Need Nick

* Rotate the recaptcha keys and switch to v3

## General Notes

* Should some of the stuff we do as jobs be live?

## Stuff to replace

* Move to_rif in collections controller to a haml template
* Should we use authenticate_users on dashboard or should cancan just do it?
* DB is all latin1 can we move to utf8mb4
* SHoudl we add has_paper_trail to party_identifier
* set set_paper_trail_whodunnit - check live db to see if it's empty for users
* Move enabling paper trail to base model and then disable on users specifically
* CHeck f.submmit :confirm should this be data?
* Can we move paper_trail to ApplicationRecord?
* permit! used for search is bad
* There dont' seem to be any graphql tests???
* grpahql schema do we want all the nulls that were included in the upgrade
* Add everything needed to search_params
* language.retired to language.retired?
* Fix comments so they are ajax again

## CRON

paper-trail can we move to JSON serialzer

## OAI

Write tests for

```
/oai/item?verb=Identify
/oai/item?verb=ListMetadataFormats
/oai/item?verb=ListSets # Not Supported
/oai/item?verb=ListRecords&metadataPrefix=olac
/oai/item?verb=ListRecords&metadataPrefix=oai_dc
/oai/collection?verb=ListRecords&metadataPrefix=olac
/oai/collection?verb=ListRecords&metadataPrefix=oai_dc
/oai/collection?verb=ListRecords&metadataPrefix=rif
/oai/item?verb=ListRecords&metadataPrefix=olac&from=2023-02-25
/oai/item?verb=ListRecords&metadataPrefix=olac&from=1970-01-01T00:00:00Z&until=2000-12-31T23:59:59Z"
/oai/item?verb=GetRecord&identifier=oai:paradisec.org.au:AA1-002&metadataPrefix=olac
/oai/collection?verb=GetRecord&identifier=oai:paradisec.org.au:AA1&metadataPrefix=olac
/oai/item?resumptionToken=oai_dc.f%282023-01-17T13%3A00%3A00Z%29.u%282023-02-23T15%3A00%3A30Z%29%3A18640&verb=ListRecords
/oai/item?verb=ListIdentifiers&metadataPrefix=oai_dc
```
