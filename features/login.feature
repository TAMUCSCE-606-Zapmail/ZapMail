Feature: User Login
  As a returning user
  So that I can access my dashboard
  I want to log in with my registered credentials and see my dashboard within 2 seconds

  Background:
    Given a registered user exists

  Scenario: Successful login
    When I visit the login page
    And I submit valid credentials
    Then I should see my dashboard
    And the login process should complete within 2 seconds
