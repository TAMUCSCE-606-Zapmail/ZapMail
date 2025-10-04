Feature: Initial Deployment
  As a developer
  I want the Rails app deployed to Heroku
  So that stakeholders can access the live version and I can test production behavior

  Scenario: Heroku app is reachable
    Given the Heroku app URL is set
    When I send a request to the app
    Then I should receive a successful response

  Scenario: Home page displays correctly
    Given the Heroku app URL is set
    When I visit the home page
    Then I should see the application title
