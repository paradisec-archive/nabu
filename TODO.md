# TODO

## Migration
* Monitoring
* Clean up SPF records
* Remove checksum files from the repository
* Clean up Media::New
* FIx DB and S3 filenames and extensions
* qua files are these quarantine with viruses?
* Check with nick about removing pfsx
* Update essence after_create :update_catalog_file efore_destroy :update_catalog_file

## Need Nick
* Rotate the recaptcha keys and switch to v3

# Security
* Had to add lots of optional => true, are they really or should we fix the tests?

# General Notes
* Should some of the stuff we do as jobs be live?

## Stuff to replace
* Add storage to NABU so we don't lose anything when containers die
* Remove to_csv in collections, and replace with standard CSV. Similar to the service used for items
* Move to_rif in collections controller to a haml template
* Should we use authenticate_users on dashboard or should cancan just do it?
* items_query_builder - here be dragons? Is this SQL injections safe, or is it building a SOLR query? Is there a better way?
* Should we use active job and let it use delayed_job
* DB is all latin1 can we move to utf8mb4
* SHoudl we add has_paper_trail to party_identifier
* set set_paper_trail_whodunnit - check live db to see if it's empty for users
* Move enabling paper trail to base model and then disable on users specifically
* streamio-ffmpeg replace with something more modern
* ditch timeliness - overkill and outdated
* Test CSRF on graphql
* CHeck f.submmit :confirm should this be data?
* Can we move paper_trail to ApplicationRecord?
* permit! used for search is bad
* Do we need to drop jquery?
* Should we be using image_processing?
* Can we get rid of all the monkeypatches?
* There dont' seem to be any graphql tests???
* grpahql schema do we want all the nulls that were included in the upgrade
* Add everything needed to search_params
* The item clause builder should probably use solr and not sql
* language.retired to language.retired?

# CRON
paper-trail can we move to JSON serialzer
*transform_images looks like it checks everything and then skips if it exists we should keep track

# OAI

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



