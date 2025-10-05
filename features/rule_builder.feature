Feature: Rule Builder
    As a user
    So that I can filter my recipients
    I want to create a rule with conditions (column, operator, value) and preview which rows are selected before saving

  Scenario: RuleProcessor generates correct results
        Given I have the following rules:
        | conditions                  | action                                     |
        | [{"column":"age","operator":">","value":18}] | {"subject":"Adult","body":"Hello {name}"} |
        And I have the following data:
        | name  | age |
        | Alice | 20  |
        | Bob   | 16  |
        When I process the rules
        Then I should see 1 result
        And the first result's substituted_subject should be "Adult"
        And the first result's substituted_body should be "Hello Alice"

    Scenario: Evaluate all condition operators
        Given a set of rules with various operators
        And corresponding data rows
        When I process the rules
        Then each rule should be evaluated correctly
    
    @javascript
    Scenario: Successfully create a new template
        Given a user exists with email "test@example.com" and password "password123"
        And Slack notifications are disabled
        And I log in as "test@example.com" with password "password123"
        When I visit the new template page
        And I enter "Test1234" as my template name
        And I enter a valid Google Sheet URL
        And I click the Verify & Load button
        And I select column "Email" as my condition rule column
        And I select operator "contains" as my condition rule operator
        And I fill in "yourcompany" as my condition rule value
        And I select column "Email" as my Email To column
        And I fill in "@Username" as my email subject
        And I fill in "Thank you!" as my email body
        And I set the schedule date-time to "2025-12-15T14:30"
        And I save my template
        And I close the template
        Then I should see "Test1234"

    @javascript
    Scenario: Successfully update an existing template
        Given a user exists with email "test@example.com" and password "password123"
        And Slack notifications are disabled
        And I log in as "test@example.com" with password "password123"
        And I have an existing template named "Test1234" with rules and a valid spreadsheet url
        When I visit the edit page for my "Test1234" template
        And I change the template name to "Test5678"
        And I save my template
        And I visit the templates page
        Then I should see "Test5678"
    
    Scenario: Sad path for template creation
        Given a user exists with email "test@example.com" and password "password123"
        And Slack notifications are disabled
        And I log in as "test@example.com" with password "password123"
        When I visit the new template page
        And I enter "" as my template name   
        And I enter a valid Google Sheet URL
        And I submit the template form directly
        Then nothing happens
    
    Scenario: Sad path for updating a template
        Given a user exists with email "test@example.com" and password "password123"
        And Slack notifications are disabled
        And I log in as "test@example.com" with password "password123"
        And I have an existing template named "Test1234" with rules and a valid spreadsheet url
        When I submit the template update directly
        Then nothing happens

    Scenario: Delete an existing template
        Given a user exists with email "test@example.com" and password "password123"
        And Slack notifications are disabled
        And I log in as "test@example.com" with password "password123"
        And I have an existing template named "Test1234" with rules and a valid spreadsheet url
        When I visit the templates page
        And I delete the template named "Test1234"
        Then I should not see "Test1234"
    

    Scenario: Successfully duplicate a template
        Given a user exists with email "test@example.com" and password "password123"
        And Slack notifications are disabled
        And I log in as "test@example.com" with password "password123"
        And I have an existing template named "Test1234" with rules and a valid spreadsheet url
        When I visit the templates page
        And I duplicate the template named "Test1234"
        Then I should see "Test1234 (Copy)"
    
    @duplicate_sad_path
    Scenario: Fails to duplicate a template
        Given a user exists with email "test@example.com" and password "password123"
        And Slack notifications are disabled
        And I log in as "test@example.com" with password "password123"
        And I have an existing template named "Test1234" with rules and a valid spreadsheet url
        When I submit a duplicate request directly for template "Test1234"
        Then nothing happens



