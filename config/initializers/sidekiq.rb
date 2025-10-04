# config/initializers/sidekiq.rb

require 'sidekiq'
require 'openssl'

redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')

# Configure SSL parameters for Redis connections
redis_config = if redis_url.start_with?('rediss://')
                 # For production Redis with SSL, disable certificate verification
                 # WARNING: This is a security risk but may be required for some hosting providers
                 {
                   url: redis_url,
                   ssl: {
                     verify_mode: OpenSSL::SSL::VERIFY_NONE,
                     verify_hostname: false
                   }
                 }
               else
                 # For non-SSL Redis connections
                 { url: redis_url }
               end

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
