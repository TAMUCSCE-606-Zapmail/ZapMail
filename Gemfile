source "https://rubygems.org"

# Main Rails Framework
gem "rails", "~> 8.0.2", ">= 8.0.2.1"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "propshaft"
gem "jbuilder"

# Asset Pipeline & Frontend
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"

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
gem "kaminari" # For pagination

group :development, :test do
  # FIX: Correct the require path for the debug gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Testing
  gem "rspec-rails"
  gem "rails-controller-testing"
  gem "dotenv-rails"

  # Static Analysis
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "rails-controller-testing"
  gem 'cucumber-rails', require: false
  gem 'capybara'           
  gem 'database_cleaner-active_record'
  gem 'simplecov', require: false
end

group :development do
  # Development-specific tools
  gem "web-console"
  gem "letter_opener_web"
end
