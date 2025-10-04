# config/initializers/sidekiq.rb

require 'sidekiq'
require 'openssl' # <--- CRITICAL: Make sure this line is present!

redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')

# This logic attempts to disable verification (OpenSSL::SSL::VERIFY_NONE is 0)
ssl_params = if redis_url.start_with?('rediss://')
               # NOTE: verify_mode: OpenSSL::SSL::VERIFY_NONE is a security risk.
               # Only use this if required by your hosting provider.
               { ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE } }
             else
               {}
             end

Sidekiq.configure_server do |config|
  # Merge the ssl parameters directly into the redis configuration hash
  config.redis = { url: redis_url }.merge(ssl_params)
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }.merge(ssl_params)
end
