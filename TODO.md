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






# Security
* the secret_token is in git!! Anyone could decode the cookies, check if this is a real security issue
