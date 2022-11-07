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

## 4.0.0
* Check upgrade guides for
  * activeadmin 0.6.3 -> 1.0.0.pre5
  * capitrano 2 -> 3
  * formatastic 2 -> 3
  * haml 4-> 5
  * haml_rail 0.4 -> 1
  * oai 0.3 -> 1.1
  * paper_trail 2 -> 7
  * sunspot 1 -> 2
  * rspec_rails
* autoprefixer-rails was deprected. Use Node.js’s Autoprefixer with PostCSS instead.
* guard-sunspot doesn't work with newer versions
* Do we need patch on form_for or does it work it out?
* Should versions_controller exist?
* Rails 4.0 removed the ActionController::Base.asset_path option. Use the assets pipeline feature. - This is only in coffeescript, releavnt?
* Check link_to that move from confirm -> data-confirm works
* CHeck f.submmit :confirm should this be data?
* Check if vendor/assets are being pulled in properly. Maybe even move away from vendoring, can't we use gems?
* Move to cookie sessions? Looks like moved to active record due to size of flash message with spreadsheets #419
* require_tree in appication.js
* application.css is missing in assets
*Remove IE 8 support
* turbolinks in layout
* config/developement.rb: do we need to set autoload paths
* config/developement.rb: do we need to set unloadable constants
* config/production.rb: should we use sass insteadof uglifier?
* config/production.rb: Do we need to add precompile assets or can SASS/turbolinks take care of it for us
* application.rb the nabu paths are also in production why duplicated?
* Why is google crawling disabled
* Rakefile : should grapql be here or in tasks directory
* https://relishapp.com/rspec/rspec-rails/v/3-9/docs/upgrade
* Move away from phantomjs

## 4.1
* Upgrades
* layouts turbolinks stuff
* Move secrets.yml to ENV in production


# 4,2
* paper_trail 7 to 10

# 5.0
* does puma replace unicorn?
* Can we move paper_trail to ApplicationRecord?
* update deprecation 7.3 Halting Callback Chains via throw(:abort)
* Do we need the paper_trail association tracking gem
* sunspot_rails upgrade to latest redo the configs 
* permit! used for search is bad

# 5.1
Do we need to drop jquery?

# 5.2
* formtastic 3 -> 4
* paper_tril  10 -> 12
* rubucop-grqapl
* credential.yml.enc and master.key and delete secrets.yml??

# 6.0
* Should we be using image_processing?
* paper_trail 12 -> 13
* javascripts directory moved??
* Can we get rid of all the monkeypatches?
* There dont' seem to be any graphql tests???
* grpahql schema do we want all the nulls that were included in the upgrade
* All the JS will br broken as we moved to webpack
* active admin css do we need any of the includes?
* ditch jquery??
MOOOOOOO bring back asctive_admin stylesheet
Need to get rid of apparition - using git version to make it work
* Do we need to add bootstrap back?
* Do something with analytical gem
*Move the stuff in vnedor js to using npm
* Add everything needed to search_params
