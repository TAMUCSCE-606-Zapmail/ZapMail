Feature: Automated Delivery
    As a user
    So that I can meet campaign deadlines
    I want emails to be enqueued by the scheduler at the configured time and sent automatically using the mailer

    Background:
        Given a user exists with email "test@example.com"
        And a template exists named "TestTemplate"
        And Slack notifications are spied

    Scenario: Successful email delivery
        Given I have an automation with a template and action data
        When I perform the email sender job for that automation
        Then Slack should be notified of success
        And an email should be sent to the automation's recipient
        And the automation's status should be "completed"

    Scenario: AI content generation fails
        Given I have an automation with a template and action data
        And AI content generation is stubbed to raise an error
        When I perform the email sender job for that automation
        Then Slack should be notified of AI failure
        And an email should be sent to the automation's recipient
        And the automation's status should be "completed"

    Scenario: General job failure
        Given I have an automation with a template and action data
        And sending email is stubbed to raise an error
        When I perform the email sender job for that automation
        Then Slack should be notified of a critical error
        And the automation's status should be "failed"
