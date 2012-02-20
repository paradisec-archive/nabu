Feature: Home Page
  In order to start using the app
  As a user
  I want to have a home page

  Scenario: Logged out users get home page
    Given I am signed out
      And I go to the home page
     Then I should see "Nabu is a digital media"

  Scenario: Signed in users get dashboard
    Given a user exists
      And I am signed in as that user
      And I go to the home page
     Then I should see "Dashboard"

