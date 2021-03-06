Feature: Log in using my RHD registered details.

  As a developers.redhat customer,
  I want to log in the site,
  So that I can use its services.

  @mobile @smoke
  Scenario: A mobile site visitor has the options to log in and register via the mobile menu.
    Given I am on the Home page
    When I tap on Menu menu item
    Then I should see a primary nav bar with the following tabs:
      | Login    |
      | Register |

  @desktop @smoke
  Scenario: A desktop site visitor has the options to log in and register via primary navigation bar.
    Given I am on the Home page
    Then I should see a primary nav bar with the following tabs:
      | Login    |
      | Register |

  @logout @basic_login
  Scenario: A customer whom has the correct login credentials can log in using their username
    Given I am on the Login page
    When I log in with a valid username
    Then I should be logged in

  @logout @basic_login
  Scenario: A customer whom has the correct login credentials can log in using their email address
    Given I am on the Login page
    When I log in with a valid email address
    Then I should be logged in

  Scenario: A customer has incorrect login credentials (the password is incorrect)
    Given I am on the Login page
    When I log in with an incorrect password
    Then the following error message should be displayed: Invalid login or password.

  Scenario: A customer tries to login with an invalid email address (e.g. xxx@xx)
    Given I am on the Login page
    When I log in with an invalid email address
    Then the following error message should be displayed: Invalid login or password.

  @logout @basic_login
  Scenario: Successful logout
    Given I am on the Login page
    When I log in with a valid password
    Then I should be logged in
    And I click the Logout link
    Then I should be logged out

  @nightly @basic_login
  Scenario: A customer who has forgotten their login details can request a password reset
    Given I am on the Login page
    When I click the forgot password link
    And submit my email address
    Then I should see a confirmation message: "You will receive an email shortly with instructions on how to create a new password. TIP: Check your junk or spam folder if you are unable to find the email."
    And I should receive an email containing a password reset link

  @logout @nightly @basic_login
  Scenario: A customer can successfully reset their password
    Given I am on the Login page
    When I click the forgot password link
    And submit my email address
    And I navigate to the password reset URL
    Then I should see a confirmation message: "You need to change your password to activate your account."
    When I update my password
    Then I should be logged in

  @logout
  Scenario: New User can login with active OpenShift.com account (simple user account)
    Given I am on the Login page
    When I log in with an active OpenShift.com account
    Then I should be asked to fill in mandatory information with a message "We need you to provide some additional information in order to continue."
    And I complete the required additional information
    Then I should be logged in

  @logout
  Scenario: New User can login with active Red Hat Customer Portal account (full user account).
    Given I am on the Login page
    And I log in with a active Customer portal account
    Then I should be asked to fill in mandatory information with a message "We need you to provide some additional information in order to continue."
    When I accept the RHD terms and conditions
    Then I should be logged in

  Scenario: User can't login with deactivated Red Hat Customer Portal account (full user account)
    Given I am on the Login page
    When I log in with a deactivated Customer portal account
    Then the following error message should be displayed: Your Red Hat user account is disabled, contact Customer Service at customerservice@redhat.com please.

