# TODO

# Security
* the secret_token is in git!! Anyone could decode the cookies, check if this is a real security issue
* Move capctha secrets our of git
& Had to add lots of optional => true, are they really or should we fix the tests?

# Upgrades

## Stuff to replace
* Remove to_csv in collections, and replace with standard CSV. Similar to the service used for items
* Move to_rif in collections controller to a haml template
* Write OAI tests and get rid of the monkey patch once we have data to test with
* CHeck out lib/oai_provider is this more monkeypatching?
* DItch analytical gem once we can find out which google analytics is being used https://dev.to/tylerlwsmith/using-google-analyticss-gtagjs-with-turbolinks-5coa

## 4.0.0
* Check upgrade guides for
  * activeadmin 0.6.3 -> 1.0.0.pre5
  * cancancan 1.13.1 -> 3.14.0
  * capitrano 2 -> 3
  * devise 2 -> 3
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
* Can the cancan locale be put in their own file
* application.rb the nabu paths are also in production why duplicated?
* Why is google crawling disabled
* Rakefile : should grapql be here or in tasks directory
* https://relishapp.com/rspec/rspec-rails/v/3-9/docs/upgrade
* Move away from phantomjs

## 4.1
* Upgrades
  * devise 3.5 -> 4.8
  * kaminar 0.17 -> 1.2
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
