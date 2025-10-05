Feature: Strategy Preview
    As a user
    So that I can confirm my setup
    I want to preview the list of recipients matching my strategy rules in less than 5 seconds before scheduling

    Scenario: Preview succeeds with valid rules and spreadsheet
        Given a user exists with email "test@example.com" and password "password123"
        And Slack notifications are disabled
        And I log in as "test@example.com" with password "password123"
        And I have an existing template named "Test1234" with rules and a valid spreadsheet url
        When I send a preview request for the template "Test1234"
        Then I should see the preview results

    Scenario: Preview fails with invalid spreadsheet
        Given a user exists with email "test@example.com" and password "password123"
        And Slack notifications are disabled
        And I log in as "test@example.com" with password "password123"
        And I have an existing template named "Test1234" with rules and a valid spreadsheet url
        When I send a preview request for the template "Test1234" with an invalid spreadsheet URL
        Then I should see a preview error message