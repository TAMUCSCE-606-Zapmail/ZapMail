Feature: Automation History
    As a user
    I want to see all email send statuses stored in AutomationHistory
    so I can review campaign outcomes

    Background:
        Given a user exists with email "test@example.com" and password "password123"
        And I log in as "test@example.com" with password "password123"

    Scenario: View all automations
        Given I have the following automations:
            | template_name | status     | send_at             |
            | TestTemplate1 | scheduled  | 2025-10-06 10:00   |
            | TestTemplate2 | completed  | 2025-10-05 14:00   |
        When I visit the automations page
        Then I should see "TestTemplate1"
        And I should see "TestTemplate2"

    Scenario: Filter automations by status
        Given I have the following automations:
            | template_name | status     | send_at             |
            | TestTemplate1 | scheduled  | 2025-10-06 10:00   |
            | TestTemplate2 | completed  | 2025-10-05 14:00   |
        When I visit the automations page with status "scheduled"
        Then I should see "TestTemplate1"
        And I should not see "TestTemplate2"

    Scenario: View a single automation
        Given I have an automation with template "TestTemplate1" and status "scheduled"
        When I visit the automation details page for "TestTemplate1"
        Then I should see the automation's template name "TestTemplate1"
        And I should see the automation's status "scheduled"

    Scenario: Attempt to view a non-existent automation
        When I visit the automation details page for ID 99999
        Then I should see an error message "The automation you were looking for could not be found."