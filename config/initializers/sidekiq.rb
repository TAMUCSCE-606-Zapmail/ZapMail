# config/initializers/sidekiq.rb

require 'sidekiq'
require 'openssl'
require 'redis'

redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')

# Configure Redis connection with SSL bypass for production
if redis_url.start_with?('rediss://')
  # Create a custom Redis connection that bypasses SSL verification
  # WARNING: This is a security risk but may be required for some hosting providers
  
  # Parse the Redis URL to extract components
  uri = URI.parse(redis_url)
  
  # Create Redis client with SSL verification disabled
  redis_client = Redis.new(
    host: uri.host,
    port: uri.port,
    password: uri.password,
    db: uri.path&.split('/')&.last&.to_i || 0,
    ssl: true,
    ssl_params: {
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
      verify_hostname: false
    }
  )
  
  redis_config = { client: redis_client }
else
  redis_config = { url: redis_url }
end

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
