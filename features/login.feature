Feature: User Login
  As a returning user
  So that I can access my dashboard
  I want to log in with my registered credentials and see my dashboard within 2 seconds

  Background:
    Given a user exists with email "test@example.com" and password "password123"

  Scenario: Successful login
    When I visit the login page
    And I submit valid credentials
    Then I should see my dashboard
    And the login process should complete within 2 seconds

  Scenario: Logging in with invalid credentials
    When I log in as "test@example.com" with password "wrongpassword"
    Then I should see "Invalid email or password."
    And I should be on the login page

  Scenario: Accessing a protected page while logged in
    When I log in as "test@example.com" with password "password123"
    And I visit the templates page
    Then I should see "Your Templates"

  Scenario: Global error handling
    When I visit a page that raises an unhandled exception
    Then I should see "Something went wrong"
  
  Scenario: Unauthenticated user cannot access protected page
    When I visit the protected test page
    Then I should be redirected to the login page
    And I should see an authorization error

  Scenario: Logged-in user can log out
    Given Slack notifications are disabled
    When I log in as "test@example.com" with password "password123"
    And I log out
    Then my JWT cookie should be cleared
    And I should see a flash message "You have successfully logged out."
    And Slack should be notified of the logout for "test@example.com"
    And I should be redirected to the home page