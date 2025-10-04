# config/initializers/sidekiq.rb

require 'sidekiq'

redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')

Sidekiq.configure_server do |config|
  config.redis = if redis_url.start_with?('rediss://')
                   { url: redis_url, ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE } }
                 else
                   { url: redis_url }
                 end
end

Sidekiq.configure_client do |config|
  config.redis = if redis_url.start_with?('rediss://')
                   { url: redis_url, ssl: { verify_mode: OpenSSL::SSL::VERIFY_NONE } }
                 else
                   { url: redis_url }
                 end
end
