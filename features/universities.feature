Feature: Universities
  In order to
  As an admin
  I want to manage universities

  Background:
    Given an admin user exists
      And I am signed in as that admin user

  Scenario: List Universities
    Given a university exists with name: "University of New South Wales"
      And a university exists with name: "University of Sydney"
     When I go to the home page
      And I follow "Browse Universities"
     Then I should see "University of New South Wales"
      And I should see "University of Sydney"

  Scenario: Add Universities
     When I go to the home page
      And I follow "Browse Universities"
     Then I should not see "Clown University"
     When I fill in "university_name" with "Clown University"
      And I press "Add"
     Then I should see "University was successfully created."
      And I should see "Clown University"

  Scenario: Delete University
    Given a university exists with name: "University of New South Wales"
      And a university exists with name: "University of Sydney"
     When I go to the home page
      And I follow "Browse Universities"
     Then I should see "University of New South Wales"
      And I should see "University of Sydney"
      # Brittle
     When I follow "Delete"
     Then I should see "University was deleted."
     Then I should not see "University of New South Wales"
      And I should see "University of Sydney"

  Scenario: Edit University
    Given a university exists with name: "University New South Wales"
     When I go to the home page
      And I follow "Browse Universities"
     Then I should see "University New South Wales"
     When I follow "Edit"
      And I fill in "Name" with "University New South Wales"
      And I press "Update"
     Then I should see "University was successfully updated."
      And I should see "University New South Wales"

  Scenario: Only admins can see universities
    Given a user exists
      And I am signed out
      And I am signed in as that user
     When I go to the home page
     Then I should not see "Browse Universities"
     When I go to the universities page
     Then I should see "Not authorized to index university."

