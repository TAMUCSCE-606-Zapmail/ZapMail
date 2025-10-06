Feature: Edit User Profile
  As a user
  so that I can keep my account information accurate, 
  I want to edit my profile details (name, email, password) and save changes within 3 seconds, with immediate confirmation

  Background:
    Given a user exists with email "test@example.com" and password "password123"
    And I log in as "test@example.com" with password "password123"

  Scenario: Successfully update profile
    When I visit the edit profile page
    And I fill in "Name" with "Updated Name"
    And I fill in "Email" with "updated@example.com"
    And I fill in "Password" with "newpassword123"
    And I fill in "Password confirmation" with "newpassword123"
    And I submit the profile form
    Then I should see "Your profile has been updated successfully."
    And the user's name should be "Updated Name"
    And the user's email should be "updated@example.com"

  Scenario: Fail to update profile due to invalid input
    When I visit the edit profile page
    And I fill in "Email" with ""
    And I submit the profile form
    Then I should see an error message about missing fields
    And the user's email should be "test@example.com"