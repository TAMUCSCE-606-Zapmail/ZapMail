Feature: Initial Database Setup
  As a developer
  I want the Postgres database set up and migrated
  So that the application can store and retrieve user and app data

  Background:
    Given the Rails environment is loaded

  Scenario: Database connection is established
    When I check the database connection
    Then the connection should be successful

  Scenario: Database has been migrated
    When I query the schema version
    Then it should not be empty

  Scenario: Application can store and retrieve data
    Given a sample user record is created in the database
    When I retrieve that record
    Then it should match the original data
