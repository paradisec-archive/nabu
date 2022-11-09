# TODO

# Security
* the secret_token is in git!! Anyone could decode the cookies, check if this is a real security issue
* Move capctha secrets our of git
& Had to add lots of optional => true, are they really or should we fix the tests?

# General NOtes

## Stuff to replace
* Remove to_csv in collections, and replace with standard CSV. Similar to the service used for items
* Move to_rif in collections controller to a haml template
* Write OAI tests and get rid of the monkey patch once we have data to test with
* CHeck out lib/oai_provider is this more monkeypatching?
* DItch analytical gem once we can find out which google analytics is being used https://dev.to/tylerlwsmith/using-google-analyticss-gtagjs-with-turbolinks-5coa
* Swithc rollbar to using an environemtn variable for deploy. Also update the docs to reflect this
* Is newrelic being used? Do we need it and rollbar? Check the ENV variable is set in production and how we do this
* MOve to recaptcha v3
* Rotate the recaptcha keys as they used to be in github
* Should we use authenticate_users on dashboard or should cancan just do it?
* Check production DB: can we drop password_salt on users
* items_query_builder - here be dragons? Is this SQL injections safe, or is it building a SOLR query? Is there a better way?
* Should we use active job and let it use delayed_job
* DB is all latin1 can we move to utf8mb4
* SHoudl we add has_paper_trail to party_identifier
*set set_paper_trail_whodunnit - check live db to see if it's empty for users
* Move enabling paper trail to base model and then disable on users specifically
* streamio-ffmpeg replace with something more modern
* ditch timeliness - overkill and outdated
* Test CSRF on graphql
* fix link_to :delete
* Should versions_controller exist?
* Check link_to that move from confirm -> data-confirm works
* CHeck f.submmit :confirm should this be data?
* turbolinks in layout
* Why is google crawling disabled
* layouts turbolinks stuff
* Move secrets.yml to ENV in production
* Can we move paper_trail to ApplicationRecord?
* permit! used for search is bad
* Do we need to drop jquery?
* credential.yml.enc and master.key and delete secrets.yml??
* Should we be using image_processing?
* Can we get rid of all the monkeypatches?
* There dont' seem to be any graphql tests???
* grpahql schema do we want all the nulls that were included in the upgrade
* Need to get rid of apparition - using git version to make it work
* Do something with analytical gem
* Add everything needed to search_params
