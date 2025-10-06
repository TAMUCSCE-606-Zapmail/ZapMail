# ZapMail - Technical Documentation

## Table of Contents
1. System Overview
2. Prerequisites
3. Local Development Setup
4. Architecture
5. Database Schema
6. Testing
7. Deployment
8. Development Workflow
9. Troubleshooting

---

## System Overview

**ZapMail** is a Ruby on Rails 8.0 application designed to automate bulk email campaigns based on data from CSV files. Built using agile methodology for CSCE 606 Software Engineering.

### Key Features
- CSV-based bulk email campaign automation
- Template management with rules and conditions
- Scheduled email sending via background jobs
- AI-powered email generation (OpenAI integration)
- Slack notifications for system events
- User authentication and profile management

### Technology Stack
- **Framework**: Ruby on Rails 8.0.3
- **Ruby Version**: 3.4.5
- **Database**: PostgreSQL (multi-database: primary, cache, queue, cable)
- **Web Server**: Puma (3 threads default)
- **Background Jobs**: Sidekiq with Sidekiq-Cron
- **Job Queue**: Redis (for Sidekiq) + Solid Queue (Rails 8 default)
- **Testing**: RSpec (unit), Cucumber (acceptance)
- **Code Quality**: RuboCop (Rails Omakase style)
- **Deployment**: Heroku with Docker support
- **Container**: Docker with Kamal
- **AI Integration**: OpenAI API
- **Notifications**: Slack webhooks
- **Frontend**: Hotwire (Turbo + Stimulus), Import Maps
- **File Storage**: Active Storage (local/disk in dev, configurable for S3/GCS/Azure)

---

## Prerequisites

Before setting up ZapMail locally, ensure you have the following installed:

### Required Software
- **Ruby**: 3.4.5
  ```bash
  # Using rbenv
  rbenv install 3.4.5
  rbenv global 3.4.5
  
  # Using rvm
  rvm install ruby-3.4.5
  rvm use 3.4.5
  ```

- **PostgreSQL**: 12 or higher
  ```bash
  # macOS (using Homebrew)
  brew install postgresql@14
  brew services start postgresql@14
  
  # Ubuntu/Debian
  sudo apt-get install postgresql postgresql-contrib
  sudo service postgresql start
  
  # Windows
  # Download from https://www.postgresql.org/download/windows/
  ```

- **Redis**: Required for Sidekiq
  ```bash
  # macOS
  brew install redis
  brew services start redis
  
  # Ubuntu/Debian
  sudo apt-get install redis-server
  sudo service redis-server start
  
  # Windows
  # Download from https://github.com/microsoftarchive/redis/releases
  ```

- **Bundler**: Gem dependency manager
  ```bash
  gem install bundler
  ```

- **Node.js** (optional, for asset pipeline): 18.x or higher
  ```bash
  # Using nvm
  nvm install 18
  nvm use 18
  ```

### Required API Keys
You'll need the following API keys to run the application:

1. **OpenAI API Key**: For AI-powered email generation
   - Sign up at https://platform.openai.com/
   - Generate an API key from your dashboard

2. **Slack Webhook URL** (optional): For system notifications
   - Create a Slack app at https://api.slack.com/apps
   - Enable Incoming Webhooks
   - Copy the webhook URL

---

## Local Development Setup

### Step 1: Clone the Repository

```bash
# Clone from GitHub
git clone https://github.com/TAMUCSCE-606-Zapmail/ZapMail.git
cd ZapMail

# Checkout the development branch
git checkout view-current-strategies-and-rules-v2
```

### Step 2: Install Dependencies

```bash
# Install Ruby gems
bundle install

# If you encounter any gem installation errors, try:
bundle update
```

### Step 3: Configure Environment Variables

Create a `.env` file in the root directory:

```bash
cp .env.example .env  # If .env.example exists
# OR create .env manually
touch .env
```

Create a `.env` file in the root directory with these three variables:

```env
WT_SECRET_KEY=your_generated_secret_key_here
OPENAI_API_KEY=your_openai_api_key_here
SLACK_WEBHOOK_URL=your_slack_webhook_url_here
```

Generate your secret key with:
```bash
rails secret
```

### Step 4: Setup PostgreSQL Database

```bash
# Update config/database.yml if needed with your PostgreSQL credentials
# The default configuration expects:
# - Host: localhost
# - Username: postgres
# - Password: admin

# Create the databases
rails db:create

# Run migrations
rails db:migrate

# (Optional) Seed the database with sample data
rails db:seed
```

If you encounter connection errors:
```bash
# Check if PostgreSQL is running
# macOS
brew services list | grep postgresql

# Linux
sudo service postgresql status

# Verify credentials by connecting manually
psql -U postgres -h localhost
```

### Step 5: Verify Installation

```bash
# Run the Rails console to verify everything is set up
rails console

# Test database connection
> User.count
# Should return 0 or the number of seeded users

# Exit console
> exit
```

### Step 6: Start the Development Server

```bash
# Install foreman if not already installed
gem install foreman

# Start all services (web server + sidekiq)
foreman start -f Procfile.dev
```
This starts:

Web server (bin/rails server) - Runs on http://localhost:3000
Tailwind CSS watcher (bin/rails tailwindcss:watch) - Compiles CSS changes

For background jobs, you'll need to run Sidekiq in a separate terminal:
bundle exec sidekiq -C config/sidekiq.yml

### Step 7: Access the Application

Open your browser and navigate to:
- **Application**: http://localhost:3000
- **Sidekiq Dashboard**: http://localhost:3000/sidekiq (development only)
- **Letter Opener** (email preview): http://localhost:3000/letter_opener (development only)

### File Storage Configuration

ZapMail uses **Active Storage** for file uploads (CSVs, attachments).

**Configuration** (config/storage.yml):
```yaml
# Development/Test: Local disk storage
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>

test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>
```
Files are stored locally on disk in the storage/ directory during development and testing.

---

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Browser                            │
└──────────────────────┬──────────────────────────────────────────┘
                       │ HTTP/HTTPS
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Rails Application                            │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐              │
│  │Controllers │  │   Models   │  │    Views     │              │
│  │            │◄─┤            │◄─┤  (ERB/HTML)  │              │
│  └────────────┘  └────────────┘  └──────────────┘              │
│         │              │                                         │
│         ▼              ▼                                         │
│  ┌────────────────────────────────────────────┐                │
│  │         Business Logic Layer                │                │
│  │  - Email Campaign Management                │                │
│  │  - Template Processing                      │                │
│  │  - CSV Data Parsing                         │                │
│  │  - Rule Engine                              │                │
│  └────────────────────────────────────────────┘                │
└──────────────┬───────────────────┬──────────────────────────────┘
               │                   │
               ▼                   ▼
┌──────────────────────┐  ┌──────────────────────┐
│   PostgreSQL DB      │  │   Sidekiq (Redis)    │
│                      │  │                      │
│  - Users             │  │  - Background Jobs   │
│  - Templates         │  │  - Scheduled Tasks   │
│  - Automations       │  │  - Email Sending     │
└──────────────────────┘  └──────────────────────┘
               │                   │
               ▼                   ▼
┌───────────────────────────────────────────────┐
│          External Services                     │
│  ┌──────────────┐  ┌──────────────────────┐  │
│  │  OpenAI API  │  │  Slack Notifications │  │
│  │              │  │                      │  │
│  │ Email Content│  │   System Alerts      │  │
│  │  Generation  │  │                      │  │
│  └──────────────┘  └──────────────────────┘  │
└───────────────────────────────────────────────┘
```

### Application Structure

```
ZapMail/
├── app/
│   ├── controllers/        # Request handlers
│   │   ├── application_controller.rb
│   │   ├── sessions_controller.rb    # Authentication
│   │   ├── users_controller.rb       # User management
│   │   ├── templates_controller.rb   # Template CRUD
│   │   └── automations_controller.rb # Campaign history
│   ├── models/             # Data models & business logic
│   │   ├── user.rb         # User authentication & profile
│   │   ├── template.rb     # Email template with rules
│   │   └── automation.rb   # Scheduled email campaigns
│   ├── views/              # HTML templates
│   ├── helpers/            # View helpers
│   └── jobs/               # Background jobs (Sidekiq)
├── config/
│   ├── database.yml        # Database configuration
│   ├── routes.rb           # URL routing
│   └── environments/       # Environment-specific configs
├── db/
│   ├── migrate/            # Database migrations
│   └── schema.rb           # Current database schema
├── spec/                   # RSpec unit tests
├── features/               # Cucumber acceptance tests
└── lib/                    # Custom libraries
```

### Application Routes

The application provides the following routes (config/routes.rb):

#### Public Routes
- `GET /` - Home page
- `GET /signup` - User registration form
- `GET /login` - Login form
- `POST /login` - Create session
- `DELETE /logout` - Destroy session

#### User Management
- `POST /users` - Create new user
- `GET /profile` - View user profile
- `GET /profile/edit` - Edit profile form
- `PATCH /profile` - Update profile

#### Template Management
- `GET /templates` - List all templates
- `GET /templates/new` - New template form
- `POST /templates` - Create template
- `GET /templates/:id` - View template
- `GET /templates/:id/edit` - Edit template form
- `PATCH /templates/:id` - Update template
- `DELETE /templates/:id` - Delete template
- `POST /templates/:id/preview` - Preview email
- `POST /templates/:id/schedule` - Schedule campaign
- `POST /templates/:id/duplicate` - Duplicate template
- `POST /templates/verify_spreadsheet` - Verify CSV/spreadsheet URL

#### Automation History
- `GET /automations` - List all campaigns
- `GET /automations/:id` - View campaign details

#### Developer Tools (Development Only)
- `GET /sidekiq` - Sidekiq dashboard
- `GET /letter_opener` - Email preview tool

#### Health Check
- `GET /up` - Rails health check endpoint

### Request Flow

1. **User Request** → Routes (`config/routes.rb`)
2. **Controller Action** → Processes request, interacts with models
3. **Model Layer** → Business logic, database interactions
4. **Background Job** (if needed) → Sidekiq processes async tasks
5. **View Rendering** → Returns HTML response
6. **Response** → Sent back to client

### Frontend Architecture

ZapMail uses **Import Maps** for JavaScript module management (no webpack/esbuild required):

**Import Map Configuration** (config/importmap.rb):
```ruby
pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/request.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "tributejs", to: "https://esm.run/tributejs@5.1.3"
```

Features:
- **Turbo**: Fast page loads without full refreshes
- **Stimulus**: Lightweight JavaScript framework
- **Tributejs**: Autocomplete/mentions functionality
- **Import Maps**: ES6 modules without bundling

---

## Database Schema

### Entity Relationship Diagram

```
┌─────────────────────────┐
│        Users            │
├─────────────────────────┤
│ id (PK)                 │
│ name                    │
│ email (unique)          │
│ password_digest         │
│ date_of_birth           │
│ major                   │
│ classification          │
│ uin (unique)            │
│ created_at              │
│ updated_at              │
└───────┬─────────────────┘
        │
        │ 1:N
        │
        ▼
┌─────────────────────────┐
│      Templates          │
├─────────────────────────┤
│ id (PK)                 │
│ name                    │
│ spreadsheet_url         │
│ rules_data (jsonb)      │
│ user_id (FK)            │
│ created_at              │
│ updated_at              │
└───────┬─────────────────┘
        │
        │ 1:N
        │
        ▼
┌─────────────────────────┐
│     Automations         │
├─────────────────────────┤
│ id (PK)                 │
│ template_id (FK)        │
│ user_id (FK)            │
│ status                  │
│ send_at                 │
│ enabled                 │
│ action_data (jsonb)     │
│ error_message           │
│ created_at              │
│ updated_at              │
└─────────────────────────┘
```

### Table Descriptions

#### Users Table
Stores user account information and authentication credentials.

| Column           | Type     | Constraints     | Description                    |
|-----------------|----------|-----------------|--------------------------------|
| id              | bigint   | PRIMARY KEY     | Auto-incrementing ID           |
| name            | string   | NOT NULL        | User's full name               |
| email           | string   | NOT NULL, UNIQUE| Email address (login)          |
| password_digest | string   | NOT NULL        | BCrypt hashed password         |
| date_of_birth   | date     | NULL            | User's birth date              |
| major           | string   | NULL            | Academic major                 |
| classification  | string   | NULL            | Student classification         |
| uin             | string   | UNIQUE          | University ID number           |

**Indexes:**
- `index_users_on_email` (unique)
- `index_users_on_uin` (unique)

#### Templates Table
Stores email campaign templates with rules and configuration.

| Column          | Type     | Constraints     | Description                     |
|----------------|----------|-----------------|--------------------------------|
| id             | bigint   | PRIMARY KEY     | Auto-incrementing ID           |
| name           | string   | NOT NULL        | Template name                  |
| spreadsheet_url| string   | NULL            | Google Sheets/CSV URL          |
| rules_data     | jsonb    | DEFAULT {}      | Campaign rules and conditions  |
| user_id        | bigint   | FOREIGN KEY     | Owner of template              |

**Indexes:**
- `index_templates_on_user_id`

**Foreign Keys:**
- `user_id` → `users(id)`

#### Automations Table
Tracks scheduled and executed email campaigns.

| Column        | Type     | Constraints              | Description                    |
|--------------|----------|--------------------------|--------------------------------|
| id           | bigint   | PRIMARY KEY              | Auto-incrementing ID           |
| template_id  | bigint   | FOREIGN KEY, NOT NULL    | Associated template            |
| user_id      | bigint   | FOREIGN KEY, NOT NULL    | User who created automation    |
| status       | string   | NOT NULL, DEFAULT 'scheduled' | Current status           |
| send_at      | datetime | NOT NULL                 | Scheduled send time            |
| enabled      | boolean  | NOT NULL, DEFAULT true   | Is automation active           |
| action_data  | jsonb    | NOT NULL                 | Campaign execution data        |
| error_message| text     | NULL                     | Error details if failed        |

**Indexes:**
- `index_automations_on_template_id`
- `index_automations_on_user_id`
- `index_automations_on_status`
- `index_automations_on_send_at`
- `index_automations_on_enabled`

**Foreign Keys:**
- `template_id` → `templates(id)`
- `user_id` → `users(id)`

**Status Values:**
- `scheduled` - Awaiting execution
- `processing` - Currently sending emails
- `completed` - Successfully finished
- `failed` - Encountered errors
- `cancelled` - Manually cancelled

### Database Commands

```bash
# Create new migration
rails generate migration AddColumnToTable column:type

# Run migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Reset database (⚠️ destroys all data)
rails db:drop db:create db:migrate

# View schema
rails db:schema:dump

# Database console
rails dbconsole
```

---

## Testing

ZapMail uses a comprehensive testing strategy with strict requirements:
- **90% code coverage** (Cucumber acceptance tests)
- **Zero RuboCop offenses** in Models, Controllers, Helpers, and Tests

### Testing Stack
- **RSpec**: Unit and integration tests
- **Cucumber**: Acceptance/validation tests (BDD)
- **Capybara**: Feature testing with browser simulation
- **SimpleCov**: Code coverage reporting
- **RuboCop**: Ruby style guide enforcement

### Running Tests

#### RSpec (Unit Tests)

```bash
# Run all RSpec tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run specific test
bundle exec rspec spec/models/user_spec.rb:23

# Run with documentation format
bundle exec rspec --format documentation

# Generate coverage report
COVERAGE=true bundle exec rspec
```

#### Cucumber (Acceptance Tests)

```bash
# Run all Cucumber features
bundle exec cucumber

# Run specific feature
bundle exec cucumber features/user_authentication.feature

# Run with specific profile
bundle exec cucumber -p default

# Generate HTML report
bundle exec cucumber --format html --out coverage/cucumber_report.html
```

#### Code Coverage

```bash
# Generate SimpleCov coverage report
COVERAGE=true bundle exec rspec
COVERAGE=true bundle exec cucumber

# View coverage report
open coverage/index.html  # macOS
xdg-open coverage/index.html  # Linux
start coverage/index.html  # Windows
```

#### RuboCop (Style Checking)

```bash
# Run RuboCop on all files
bundle exec rubocop

# Auto-fix safe offenses
bundle exec rubocop -a

# Run on specific directory
bundle exec rubocop app/models

# Generate HTML report
bundle exec rubocop --format html --out rubocop_report.html
```

### Test Database Setup

```bash
# Prepare test database
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate

# Reset test database
RAILS_ENV=test rails db:reset
```

### Writing Tests

#### RSpec Example

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'requires an email' do
      user = User.new(email: nil)
      expect(user).not_to be_valid
    end
  end

  describe 'associations' do
    it 'has many templates' do
      association = User.reflect_on_association(:templates)
      expect(association.macro).to eq(:has_many)
    end
  end
end
```

#### Cucumber Example

```gherkin
# features/user_authentication.feature
Feature: User Authentication
  As a user
  I want to log in to the system
  So that I can access my email campaigns

  Scenario: Successful login
    Given a user exists with email "user@example.com"
    When I visit the login page
    And I fill in "Email" with "user@example.com"
    And I fill in "Password" with "password123"
    And I click "Log In"
    Then I should see "Welcome back!"
```
---

## Deployment

### Heroku Deployment

ZapMail is deployed on Heroku with the following configuration:

**Production URL**: https://zapmail-pradeep-a162d897f0b7.herokuapp.com/

#### Prerequisites

```bash
# Install Heroku CLI
# macOS
brew tap heroku/brew && brew install heroku

# Ubuntu/Debian
curl https://cli-assets.heroku.com/install.sh | sh

# Windows
# Download installer from https://devcenter.heroku.com/articles/heroku-cli

# Login to Heroku
heroku login
```

#### Initial Heroku Setup

```bash
# Create Heroku app
heroku create zapmail-yourname

# Add PostgreSQL addon
heroku addons:create heroku-postgresql:mini

# Add Redis addon (for Sidekiq)
heroku addons:create heroku-redis:mini

# Set environment variables
heroku config:set WT_SECRET_KEY=$(rails secret)
heroku config:set OPENAI_API_KEY=your_openai_key
heroku config:set SLACK_WEBHOOK_URL=your_slack_webhook
heroku config:set RAILS_ENV=production
heroku config:set RACK_ENV=production

# Add Ruby buildpack
heroku buildpacks:add heroku/ruby
```

#### Deploying to Heroku

```bash
# Add Heroku remote (if not already added)
heroku git:remote -a zapmail-yourname

# Deploy to Heroku
git push heroku main

# If deploying from a different branch
git push heroku your-branch:main

# Run database migrations
heroku run rails db:migrate

# Seed database (if needed)
heroku run rails db:seed

# Check deployment status
heroku ps

# View logs
heroku logs --tail

# Open application
heroku open
```

#### Configuring Workers (Sidekiq)

The `Procfile` defines two process types:

```
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
```

**Sidekiq Configuration** (config/sidekiq.yml):
```yaml
:concurrency: 5
:queues:
  - default

:schedule:
  file: config/sidekiq_schedule.yml
```

**Cron Jobs** (config/sidekiq_schedule.yml):
```yaml
automation_scheduler:
  cron: "* * * * *"  # Runs every minute
  class: "AutomationSchedulerJob"
  queue: "default"
```

The `AutomationSchedulerJob` runs every minute to check for scheduled email campaigns that need to be sent.

Scale workers on Heroku:

```bash
# Start worker dyno
heroku ps:scale worker=1

# Check dyno status
heroku ps

# View worker logs
heroku logs --ps worker --tail

# Monitor Sidekiq queue
heroku run rails console
> Sidekiq::Queue.new.size
> Sidekiq::Stats.new.processed
```

#### Environment-Specific Configuration

**Production Database Configuration** (config/database.yml):

ZapMail uses Rails 8's multi-database configuration with separate databases for different concerns:

```yaml
production:
  primary:
    adapter: postgresql
    encoding: unicode
    pool: 5
    database: zapmail_production
    username: zapmail
    password: <%= ENV["ZAPMAIL_DATABASE_PASSWORD"] %>
  
  cache:
    # Separate database for caching
    database: zapmail_production_cache
    migrations_paths: db/cache_migrate
  
  queue:
    # Separate database for job queues (Solid Queue)
    database: zapmail_production_queue
    migrations_paths: db/queue_migrate
  
  cable:
    # Separate database for Action Cable
    database: zapmail_production_cable
    migrations_paths: db/cable_migrate
```

This architecture improves performance by isolating different concerns. Heroku automatically sets `DATABASE_URL`, which Rails uses for the primary database.

#### Monitoring & Maintenance

```bash
# View application logs
heroku logs --tail

# Access Rails console on production
heroku run rails console

# Run database migrations
heroku run rails db:migrate

# Restart application
heroku restart

# Check addon status
heroku addons

# View database info
heroku pg:info

# View Redis info
heroku redis:info
```

### Docker Deployment (Alternative)

ZapMail includes Docker support via Kamal for container-based deployment.

#### Build Docker Image

```bash
# Build image
docker build -t zapmail .

# Run container locally
docker run -d \
  -p 80:80 \
  -e RAILS_MASTER_KEY=$(cat config/master.key) \
  -e DATABASE_URL=your_database_url \
  --name zapmail \
  zapmail

# View logs
docker logs -f zapmail

# Stop container
docker stop zapmail
```

#### Kamal Deployment

```bash
# Setup Kamal configuration
# Edit config/deploy.yml with your server details

# Deploy with Kamal
kamal deploy

# Check status
kamal app status

# View logs
kamal app logs
```

---

## Development Workflow

### Git Branching Strategy

ZapMail uses a two-tier branch strategy:

```
feature-branch → preprod → prod → Heroku
```

#### Branch Descriptions

1. **Feature Branches**: Individual user stories or features
   - Naming: `feature/description` or `fix/bug-description`
   - Example: `view-current-strategies-and-rules-v2`

2. **Preprod Branch**: Integration testing environment
   - All changes merged here first
   - Tested with RSpec (unit tests)
   - Reviewed by team

3. **Prod Branch**: Production-ready code
   - Requires 90% Cucumber coverage
   - Zero RuboCop offenses
   - All acceptance tests must pass
   - Automatically deployed to Heroku

### Development Process

#### Step 1: Create Feature Branch

```bash
# Update local branches
git checkout preprod
git pull origin preprod

# Create new feature branch
git checkout -b feature/your-feature-name
```

#### Step 2: Develop & Test Locally

```bash
# Make changes
# Write tests (RSpec and/or Cucumber)

# Run tests
bundle exec rspec
bundle exec cucumber

# Check code style
bundle exec rubocop

# Commit changes
git add .
git commit -m "Add feature: description"
```

#### Step 3: Create Pull Request to Preprod

```bash
# Push feature branch
git push origin feature/your-feature-name

# Create PR on GitHub
# Target: preprod branch
# Include:
#   - Description of changes
#   - Related user story
#   - Screenshots (if UI changes)
#   - Test coverage report
```

**Review Checklist for Preprod PR:**
- [ ] All RSpec unit tests pass
- [ ] Code follows RuboCop style guide
- [ ] No security vulnerabilities (Brakeman)
- [ ] Reviewed by at least one team member

#### Step 4: Merge to Preprod

After approval:
```bash
# Merge via GitHub PR interface
# OR manually:
git checkout preprod
git merge --no-ff feature/your-feature-name
git push origin preprod
```

#### Step 5: Create Pull Request to Prod

```bash
# After testing in preprod
# Create PR from preprod → prod

# Run full test suite
COVERAGE=true bundle exec rspec
COVERAGE=true bundle exec cucumber
bundle exec rubocop app/models app/controllers app/helpers spec/ features/
```

**Review Checklist for Prod PR:**
- 90% Cucumber test coverage
- Zero RuboCop offenses in Models, Controllers, Helpers, Tests
- All acceptance tests pass
- No breaking changes
- Database migrations tested
- Environment variables documented

#### Step 6: Deploy to Production

```bash
# After merging to prod
git checkout prod
git pull origin prod

# Deploy to Heroku
git push heroku prod:main

# Run migrations if needed
heroku run rails db:migrate

# Monitor deployment
heroku logs --tail
```

### Code Review Guidelines

#### For Reviewers
- Check logic and implementation
- Verify test coverage
- Look for potential bugs or security issues
- Ensure code follows Rails best practices
- Confirm RuboCop compliance

#### For Authors
- Keep PRs focused and small
- Write descriptive commit messages
- Include tests for new features
- Update documentation
- Respond to review comments promptly

---

## Troubleshooting

### Common Issues

#### Database Connection Errors

**Problem**: `FATAL: role "postgres" does not exist`

**Solution**:
```bash
# Create postgres user
createuser -s postgres

# OR update config/database.yml with your username
```

**Problem**: `FATAL: database "zapmail_development" does not exist`

**Solution**:
```bash
rails db:create
rails db:migrate
```

#### Redis Connection Errors

**Problem**: `Error connecting to Redis on localhost:6379`

**Solution**:
```bash
# Check if Redis is running
redis-cli ping
# Should return: PONG

# If not running, start Redis
# macOS
brew services start redis

# Linux
sudo service redis-server start

# Windows
# Start redis-server.exe from installation directory
```



### Getting Help

If you encounter issues not covered here:

1. **Check Application Logs**
   ```bash
   # Development
   tail -f log/development.log
   
   # Production (Heroku)
   heroku logs --tail
   ```

2. **Check Test Output**
   ```bash
   bundle exec rspec --format documentation
   bundle exec cucumber --format pretty
   ```

3. **Run Diagnostic Commands**
   ```bash
   # System info
   rails about
   
   # Database info
   rails dbconsole
   \l    # List databases
   \dt   # List tables
   
   # Redis info
   redis-cli INFO
   ```

4. **Contact Team**
   - Pradeep Periyasamy (@PRADEEPPERIYASAMY)
   - Aurora Jitrskul (@ajitrskul)
   - Charlie Chiu (@pinkpig777)
   - Wang Yifei (@pwzerus)

5. **Check GitHub Issues**
   - https://github.com/TAMUCSCE-606-Zapmail/ZapMail/issues

---

## Additional Resources

- **Rails Guides**: https://guides.rubyonrails.org/
- **PostgreSQL Documentation**: https://www.postgresql.org/docs/
- **Sidekiq Documentation**: https://github.com/sidekiq/sidekiq/wiki
- **RSpec Documentation**: https://rspec.info/documentation/
- **Cucumber Documentation**: https://cucumber.io/docs/
- **Heroku Dev Center**: https://devcenter.heroku.com/
