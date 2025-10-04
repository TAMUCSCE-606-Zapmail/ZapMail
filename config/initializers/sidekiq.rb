# config/initializers/sidekiq.rb

require 'sidekiq'
require 'openssl'

redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')

# Configure Redis connection with SSL bypass for production
if redis_url.start_with?('rediss://')
  # For SSL Redis connections, use URL with SSL parameters
  # WARNING: This is a security risk but may be required for some hosting providers
  
  redis_config = {
    url: redis_url,
    ssl_params: {
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
      verify_hostname: false
    }
  }
else
  # For non-SSL Redis connections
  redis_config = { url: redis_url }
end

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
