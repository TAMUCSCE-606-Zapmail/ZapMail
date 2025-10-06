Feature: AI Draft Generation
    As a campaign manager
    So that I can save time
    I want the AI to generate an email draft within 10 seconds using my PromptTemplate and sample CSV data

    Scenario: AI successfully generates improved content
        Given I have a subject template "Welcome to ZapMail"
        And I have a body template "Hello {name}, we're excited to have you!"
        When I request AI-generated content
        Then I should receive a response with a subject and body
        And the subject should not be the same as the original
        And the body should not be the same as the original

    Scenario: AI fails and falls back to original content
        Given I have a subject template "Reminder"
        And I have a body template "Don't forget to submit your assignment."
        And the AI client is stubbed to raise an error
        When I request AI-generated content
        Then I should receive a response with the original subject and body