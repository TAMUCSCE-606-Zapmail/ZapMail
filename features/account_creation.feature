Feature: Account Creation
    As a new user
    So that I can access Zapmail
    I want to register with my email, name, and password and login with my new account

    Scenario: Successfully create a new user account
        When I visit the signup page
        And I fill in "Name" with "Test User"
        And I fill in "Email" with "test@example.com"
        And I fill in "Password" with "password123"
        And I fill in "Password confirmation" with "password123"
        And I submit the signup form
        Then I should see "Welcome to the ZapMail! Your account was created successfully."
        And a user with email "test@example.com" should exist

    Scenario: Fail to create a user due to missing required fields
        When I visit the signup page
        And I submit the signup form without filling in required fields
        Then I should see an error message about missing fields
        And no user should be created