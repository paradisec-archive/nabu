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
    Then I should see "You have signed up successfully. However, we could not sign you in because your account is unconfirmed."
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
    Then I should see "You have signed up successfully. However, we could not sign you in because your account is unconfirmed."
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

#  Scenario: Sign in and view user page
#    Given a user exists with email: "john@robotparade.com.au", password: "moocow"
#    When I go to the homepage
#    And I follow "Sign in"
#    And I fill in "Email" with "john@robotparade.com.au"
#    And I fill in "Password" with "moocow"
#    And I press "Sign in"
#    Then I should be on that user's page
#    And I should see "Sign in successful"
#    And I should see "John Ferlito" within "#login_info"
#    And I should see "John Ferlito" within "#user_details"
#    And I should see "Sign out" within "#login_info"
#    But I should not see "Sign in" within "#login_info"
#    And I should not see "Sign up" within "#login_info"
#
#  Scenario: Must be signed in to show a users page
#    Given a user exists with email: "johnf1@robotparade.com.au", first_name: "John"
#    When I go to that user's page
#    Then I should not see "John"
#    And I should see "You must be signed in to access that page"
#
#  Scenario: Edit user details
#    Given a user exists with email: "john@robotparade.com.au", password: "moocow"
#    When I go to the homepage
#    And I follow "Sign in"
#    And I fill in "Email" with "john@robotparade.com.au"
#    And I fill in "Password" with "moocow"
#    And I press "Sign in"
#    Then I should be on that user's page
#    And I follow "Edit Details"
#    Then I should be on that user's edit page
#    And I fill in "First name" with "fred"
#    And I fill in "Last name" with "freddo"
#    And I fill in "Email" with "fred@freddo.org"
#    And I fill in "Change password" with "fredfred"
#    And I fill in "Password confirmation" with "fredfred"
#    And I press "Update"
#    Then I should be on that user's page
#    And I should see "fred freddo" within "#login_info"
#    And I should see "fred@freddo.org" within "#user_details"
#    And I should see "Your account details have been updated, including password."


# This works but allow-rescue is broken in cucumber-rails
#  @allow-rescue
#  Scenario: A user can only see her own details
#    Given a user: "johnf1" exists with email: "johnf1@robotparade.com.au", first_name: "John"
#    And a user: "silvia" exists with email: "silvia@gingertech.net", first_name: "Silvia"
#    And I am signed in as user "silvia"
#    When I go to the user "silvia"'s page
#    Then I should see "Silvia" within "#content"
#    When I go to the user "johnf1"'s page
#    Then I should not see "John" within "#content"
#    And I should see "Sorry, the page you were looking for does not exist."

