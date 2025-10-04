# This file configures Sidekiq to use your Redis connection.
# The default URL assumes Redis is running on localhost:6379.
Sidekiq.configure_server do |config|
    config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
  end
  
  Sidekiq.configure_client do |config|
    config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/1') }
  end