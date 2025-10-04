# config/initializers/sidekiq.rb

require 'sidekiq'

redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')

# If the URL uses SSL (rediss://), add ssl_params for Heroku/other SSL Redis
ssl_params = if redis_url.start_with?('rediss://')
               { verify_mode: OpenSSL::SSL::VERIFY_NONE } # skip verification for self-signed certs
             else
               {}
             end

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }.merge(ssl_params)
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }.merge(ssl_params)
end
