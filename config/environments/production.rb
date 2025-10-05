require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Force all access to the app over SSL.
  config.force_ssl = true

  # Log to STDOUT.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # FIX: Comment out the Solid Cache store, as you are not using this gem.
  # config.cache_store = :solid_cache_store

  # FIX: Change the queue adapter to Sidekiq to match your Gemfile.
  # This was the line causing the crash.
  config.active_job.queue_adapter = :sidekiq
  
  # FIX: Comment out the Solid Queue database connection.
  # config.solid_queue.connects_to = { database: { writing: :queue } }

  # --- FIX: Configure Action Mailer for Production (SendGrid) ---
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: "zapmail-pradeep-a162d897f0b7.herokuapp.com" } # Use your Heroku app URL

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV['MAILGUN_SMTP_SERVER'], # smtp.mailgun.org
    port: ENV['MAILGUN_SMTP_PORT'],      # 587
    domain: ENV['MAILGUN_DOMAIN'],       # your sandbox domain
    user_name: ENV['MAILGUN_SMTP_LOGIN'], # check this, should be in config vars
    password: ENV['MAILGUN_API_KEY'],    # use the API key here if login missing
    authentication: :plain,
    enable_starttls_auto: true
  }
  
  # --- END OF FIX ---

  # Enable locale fallbacks for I18n.
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # --- ASSET PIPELINE CONFIGURATION ---
  config.assets.compile = false
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?
  config.assets.precompile += %w( application.js application.css )
end
