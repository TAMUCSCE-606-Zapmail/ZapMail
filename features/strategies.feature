Feature: Strategies management

  Background:
    Given a signed-in user

  Scenario: Viewing the list of strategies
    Given the user has 2 strategies
    When the user visits the strategies page
    Then they should see the 2 strategies listed

  Scenario: Clicking "+ New strategy" navigates to new page
    When the user visits the strategies page
    And they click the "+ New strategy" button
    Then they should be on the new strategy page
