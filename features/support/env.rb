# features/support/env.rb
require 'cucumber/rails'
require 'capybara/rails'
require 'database_cleaner/active_record'
require 'simplecov'

# ✅ Enable SimpleCov for test coverage
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  add_filter '/db/'
  add_group 'Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers', 'app/helpers'
end

# ✅ Ensure exceptions bubble up during tests
ActionController::Base.allow_rescue = false

# ✅ Configure DatabaseCleaner
begin
  DatabaseCleaner.strategy = :transaction
rescue NameError
  raise "Add database_cleaner-active_record to your Gemfile (in the :test group) if you wish to use it."
end

Cucumber::Rails::Database.javascript_strategy = :truncation
