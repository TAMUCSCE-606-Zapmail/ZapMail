Feature: Development user mocking

  Scenario: Auto sign-in or create a user in development
    Given Rails is in development mode
    And there is no user in the database
    When the user visits the root page
    Then a user should be created
    And the user should be signed in
