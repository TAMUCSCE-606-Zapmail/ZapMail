require 'sidekiq/testing'

# Use fake mode so jobs are added to a jobs array instead of being executed immediately
Sidekiq::Testing.fake!
