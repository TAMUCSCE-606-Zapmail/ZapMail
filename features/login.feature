Feature: User Login
  As a returning user
  So that I can securely access my strategies and automations
  I want to log in with my registered credentials and see my dashboard within 2 seconds

  Background:
    Given the Heroku app URL is set

  Scenario: Successful login redirects to dashboard quickly
    When I visit the login page
    And I submit valid credentials
    Then I should see my dashboard
    And the login process should complete within 2 seconds
