source "https://rubygems.org"
ruby "3.4.5"

# --- CORE GEMS (needed everywhere) ---
gem "rails", "~> 8.0.2", ">= 8.0.2.1"
gem "pg", "~> 1.1" # For PostgreSQL
gem "puma", ">= 5.0"
gem "jbuilder"
gem 'dotenv-rails'
gem "propshaft", require: false
gem "slack-notifier"

# Asset Pipeline & Frontend
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# Background Jobs
gem 'sidekiq'
gem 'sidekiq-cron'

# AI Integration
gem 'ruby-openai'

# Authentication and API
gem 'bcrypt', '~> 3.1.7'
gem 'jwt', '~> 2.7'

# Utilities
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false
gem "csv", "~> 3.3"
gem "kaminari"

# Frontend Gem for assets:precompile
gem 'sprockets-rails'

# --- DEVELOPMENT & TEST GEMS ---
# These gems will NOT be installed in production on Heroku.
group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rspec-rails"
  gem "rails-controller-testing"
  gem 'cucumber-rails', require: false
  gem 'capybara'
  gem 'database_cleaner-active_record'
  gem 'simplecov', require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

# --- DEVELOPMENT-ONLY GEMS ---
# These gems will only be used on your local machine.
group :development do
  gem "web-console"
  gem "letter_opener_web"
end
