# TODO

## General
* Display video, audio image etc in essence page

## Milestones
* Help pages (CMS?)
* CSV Metadata Import Implementation for Collection and Items
* Reporting Web Service Implementation for Workflow Monitoring, notifications

## Post Rollout
* Check all dates in collections that should have a value have one



# Upgrades

## 4.0.0
* We will need to drop compass at some stage
* Did dropping libv8 and rubyravr break anything
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
  * squeel
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
  * graphql 1.7 -> 2.0
  * kaminar 0.17 -> 1.2
* layouts turbolinks stuff
* Move secrets.yml to ENV in production


# 4,2
* paper_trail 7 to 10

# 5.0
* compas 0 -> 1
* does puma replace unicorn?
* Can we move paper_trail to ApplicationRecord?
* update deprecation 7.3 Halting Callback Chains via throw(:abort)
* Squeel unsupported
* 7.11 ActionController::Parameters No Longer Inherits from HashWithIndifferentAccess


# Clean up rubocop config




# Security
* the secret_token is in git!! Anyone could decode the cookies, check if this is a real security issue
* Move capctha secrets our of git

