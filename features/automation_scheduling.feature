Feature: Automation Scheduling
    As a user
    So that I can automate delivery
    I want to schedule my strategy as a one-time or recurring automation, with confirmation displayed immediately after scheduling

    Scenario: Successfully schedule emails from a template
        Given a user exists with email "test@example.com" and password "password123"
        And Slack notifications are disabled
        And I log in as "test@example.com" with password "password123"
        And I have an existing template named "Test1234" with rules and a valid spreadsheet url
        When I visit the edit page for my "Test1234" template
        And I send a schedule request for that template
        Then I should receive a success response with scheduled_count greater than 0
        And the template should have corresponding automation records created

    Scenario: Fails to schedule emails due to an error
        Given a user exists with email "test@example.com" and password "password123"
        And Slack notifications are disabled
        And I log in as "test@example.com" with password "password123"
        And I have an existing template named "Test1234" with rules and a valid spreadsheet url
        And I send a schedule request for that template with broken spreadsheet
        Then I should receive a failure response with an error message
