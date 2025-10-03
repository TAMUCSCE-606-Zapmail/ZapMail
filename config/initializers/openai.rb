# This file configures the OpenAI client for your application.
# It uses an environment variable to keep your API key secret.
OpenAI.configure do |config|
    config.access_token = ENV.fetch("OPENAI_API_KEY")
  end