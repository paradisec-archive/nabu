Feature: Collections
  In order to value
  As a role
  I want feature


  Background:
    Given a user exists
      And an admin user exists
      And a university exists with name: "University of Sydney"
      And a field of research exists with identifier: 420114, name: "Indonesian Languages"
      And a country exists with name: "Indonesia"
      And a language exists with code: "ski", name: "Silka"


  Scenario: Non Admin users can't add collections
    Given I am signed out
     When I go to the home page
     Then I should not see "Add Collection"
     When I go to the new collection page
     Then I should see "You need to sign in or sign up before continuing."
     When I am signed in as that user
      And I go to the home page
     Then I should see "Add Collection"
     When I go to the new collection page
     Then I should see "Add a Collection"

  @wip
  Scenario: Add a collection
    Given I am signed in as that user
      And I am on the new collection page
     When I fill in "Title" with "Alexander Adelaar Indonesia/Selaako Collection"
      And I fill in "Collection ID" with "AA1"
      And I select "University of Sydney" from "Originating Uni"
      And I select "420114 - Indonesian Languages" from "Field of Research"
      And I select "Indonesia" from "Countries"
      And I select "ski - Silka" from "Languages"
      And I fill in "Region / Village" with "Sasak Village, Samalantan"
      And I fill in "Longitude" with "108.905"
      And I fill in "Latitude" with "1.006"
      And I fill in "Zoom" with "3"
      And I fill in "Description" with "This collection is awesome\nMoo"
      And I press "Add Collection"

