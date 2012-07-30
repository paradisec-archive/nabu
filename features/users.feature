Feature: Authentication and Authorisation
  In order to interact with the website
  As a user
  I want to be able to login

  Scenario: A Sign up link should exist
    When I go to the home page
    Then I should see "Sign up"

  Scenario: Sign up an account, confirm it via email and login
    When I go to the homepage
    And I follow "Sign up"
    Then I should see "Email"
    When I fill in "Email" with "john@robotparade.com.au"
    And I fill in "First name" with "John"
    And I fill in "Last name" with "Ferlito"
    And I fill in "Password" with "moocow"
    And I fill in "Password confirmation" with "moocow"
    And I press "Sign up" within "form"
    Then I should see "A message with a confirmation link has been sent to your email address. Please open the link to activate your account."
    And "john@robotparade.com.au" should receive an email
    When I open the email
    Then I should see "Confirm my account" in the email body
    When I follow "Confirm my account" in the email
    Then I should see "Your account was successfully confirmed. You are now signed in."
    And I should see "John Ferlito"
    And I should see "Sign out"
    When I follow "Sign out"
    Then I should see "Signed out successfully."
    When I follow "Sign in"
    And I fill in "Email" with "john@robotparade.com.au"
    And I fill in "Password" with "moocow"
    And I press "Sign in"
    Then I should see "John Ferlito"

  Scenario: Sign in doesn't work after registration without confirmation
    When I go to the homepage
    And I follow "Sign up"
    Then I should see "Email"
    When I fill in "Email" with "john@robotparade.com.au"
    And I fill in "First name" with "John"
    And I fill in "Last name" with "Ferlito"
    And I fill in "Password" with "moocow"
    And I fill in "Password confirmation" with "moocow"
    And I press "Sign up"
    Then I should see "A message with a confirmation link has been sent to your email address. Please open the link to activate your account."
    And I should not see "Sign out"
    When I follow "Sign in"
    And I fill in "Email" with "john@robotparade.com.au"
    And I fill in "Password" with "moocow"
    And I press "Sign in"
    Then I should see "You have to confirm your account before continuing."

  Scenario: Sign out
    Given a user exists
    And I am signed in as that user
    When I go to the homepage
    Then I should see "Sign out"
    And I follow "Sign out"
    Then I should see "Signed out successfully."
    And I should be on the homepage

  Scenario: Reset password
    Given a user exists with email: "john@robotparade.com.au", password: "moocow"
    When I go to the homepage
     And I follow "Sign in"
     And I follow "Forgot your password?"
     And I fill in "Email" with "john@robotparade.com.au"
     And I press "Send me reset password instructions"
    Then I should see "You will receive an email with instructions about how to reset your password in a few minutes."
     And "john@robotparade.com.au" should receive an email
    When I open the email
    Then I should see "Change my password" in the email body
    When I follow "Change my password" in the email
    Then I should see "Change your password"
     And I fill in "New password" with "foobar"
     And I fill in "Confirm new password" with "foobar"
     And I press "Change my password"
    Then I should see "Your password was changed successfully. You are now signed in."
     And I should see "John Ferlito"
    When I follow "Sign out"
     And I follow "Sign in"
     And I fill in "Email" with "john@robotparade.com.au"
     And I fill in "Password" with "foobar"
     And I press "Sign in"
    Then I should see "John Ferlito"

  Scenario: Didn't recieve confirmation instructions
    Given a user exists with email: "john@robotparade.com.au", confirmed_at: false
    When I go to the home page
     And I follow "Sign in"
     And I follow "Didn't receive confirmation instructions?"
     And I fill in "Email" with "john@robotparade.com.au"
     And I press "Resend confirmation instructions"
    Then I should see "You will receive an email with instructions about how to confirm your account in a few minutes."
     And "john@robotparade.com.au" should receive 2 emails

  Scenario: Can't reconfirm a confirmed account
    Given a user exists with email: "john@robotparade.com.au", password: "moocow"
    When I go to the home page
     And I follow "Sign in"
     And I follow "Didn't receive confirmation instructions?"
     And I fill in "Email" with "john@robotparade.com.au"
     And I press "Resend confirmation instructions"
    Then I should see "Email was already confirmed, please try signing in"

  Scenario: Admin users can see the Settings menu
    Given an admin user exists
     When I go to the home page
     Then I should not see "Settings"
    Given I am signed in as that user
     Then I should see "Settings"

  Scenario: Sign in and view user page
    Given a user exists with first_name: "John", last_name: "Ferlito"
      And I am signed in as that user
     When I go to the homepage
      And I follow "John Ferlito"
     Then I should be on that user's page
      And I should see "User details"

  Scenario: Must be signed in to show a users page
    Given a user exists with first_name: "John"
    When I go to that user's page
    Then I should not see "John"
    And I should see "Not allowed to manage other user accounts."

  Scenario: Edit user details
    Given a user exists with first_name: "John", last_name: "Ferlito"
      And I am signed in as that user
     When I go to that user's page
     And I fill in "First name" with "fred"
     And I fill in "Last name" with "freddo"
     And I fill in "Address" with "1 George St, Sydney"
     And I fill in "Country" with "Australia"
     And I fill in "Phone" with "61 2 1234 5678"
     And I fill in "Email" with "fred@freddo.org"
     And I fill in "New password" with "fredfred"
     And I fill in "Repeat password" with "fredfred"
     And I fill in "Current password" with "password"
     And I press "Update"
    Then I should be on that user's page
     And I should see "fred freddo"
     And the "First name" field should contain "fred"
     And the "Last name" field should contain "freddo"
     And the "Address" field should contain "1 George St, Sydney"
     And the "Country" field should contain "Australia"
     And the "Phone" field should contain "61 2 1234 5678"
     And the "Email" field should contain "fred@freddo.org"
     And I should see "User was successfully updated."

  Scenario: A user can only see her own details
    Given a user: "johnf" exists with email: "johnf@robotparade.com.au", first_name: "John"
    And a user: "silvia" exists with email: "silvia@gingertech.net", first_name: "Silvia"
    And I am signed in as user "silvia"
    When I go to the user "silvia"'s page
    Then I should see "Silvia"
    When I go to the user "johnf"'s page
    Then I should not see "John"
    And I should see "Not allowed to manage other user accounts."

  Scenario: Admins can see a list of users
    Given an admin user "johnf" exists with first_name: "John"
      And an admin user "nick" exists with first_name: "Nick"
      And a user "silvia" exists with first_name: "Silvia"
     When I am signed in as user "johnf"
      And I go to the home page
      And I follow "Browse users"
     Then I should see "John"
      And I should see "Nick"
      And I should see "Silvia"
      # FIXME This is brittle
      When I follow "Edit" within "tr:nth-child(2)"
     Then I should be on the edit page for user "johnf"

  Scenario: Admins can delete users
    Given an admin user "johnf" exists with first_name: "John"
      And a user "silvia" exists with first_name: "Silvia"
     When I am signed in as user "johnf"
      And I go to the home page
      And I follow "Browse users"
      # FIXME This is brittle
     When I follow "Delete" within "tr:nth-child(3)"
     Then the user should not exist with first_name: "Silvia"


  Scenario: Non admins can't browse users
    Given a user exists
      And I am signed in as that user
     When I go to the home page
     Then I should not see "Browse Users"
     When I go to the users page
     Then I should see "Not allowed to manage other user accounts."

  Scenario: User search
    Given an admin user exists with first_name: "John", last_name: "Ferlito"
      And a user exists with first_name: "Silvia", last_name: "Pfeiffer"
      And a user exists with first_name: "Peter", last_name: "Piper"
      And I am signed in as that admin user
     When I go to the users page
     Then I should see "Ferlito"
      And I should see "Pfeiffer"
      And I should see "Piper"
     When I fill in "search" with "f"
      And I press "Search"
     Then I should see "Ferlito"
      And I should see "Pfeiffer"
      And I should not see "Piper"
     When I press "Clear"
     Then I should see "Ferlito"
      And I should see "Pfeiffer"
      And I should see "Piper"

    # TODO Add tet for CSV Export
