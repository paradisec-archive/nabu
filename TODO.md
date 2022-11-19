# TODO

## Need Nick
* Rotate the recaptcha keys and switch to v3
* Why is google crawling disabled

# Security
* Had to add lots of optional => true, are they really or should we fix the tests?

# General NOtes

## Stuff to replace
* Add storage to NABU so we don't lose anything when containers die
* Remove to_csv in collections, and replace with standard CSV. Similar to the service used for items
* Move to_rif in collections controller to a haml template
* Write OAI tests and get rid of the monkey patch once we have data to test with
* Check out lib/oai_provider is this more monkeypatching?
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
* fix link_to :delete
* Check link_to that move from confirm -> data-confirm works
* CHeck f.submmit :confirm should this be data?
* Can we move paper_trail to ApplicationRecord?
* permit! used for search is bad
* Do we need to drop jquery?
* Should we be using image_processing?
* Can we get rid of all the monkeypatches?
* There dont' seem to be any graphql tests???
* grpahql schema do we want all the nulls that were included in the upgrade
* Add everything needed to search_params
