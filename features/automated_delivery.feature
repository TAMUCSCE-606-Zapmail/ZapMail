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
        Then Slack should be notified of a emailsender critical error
        And the automation's status should be "failed"
    
    Scenario: No automations due
        Given there are no due automations
        When I run the scheduler job
        Then Slack should be notified that the scheduler started
        And no jobs should be enqueued

    Scenario: Some automations are due
        Given a due automation exists for "test@example.com" and template "TestTemplate" scheduled at "2025-10-05 10:00"
        When I run the scheduler job
        Then Slack should be notified about found automations
        And the due automation should be marked as processing
        And the EmailSenderJob should be enqueued for the due automation

    Scenario: Scheduler fails
        Given the scheduler job will raise an error
        When I run the scheduler job
        Then Slack should be notified of a scheduler critical error
