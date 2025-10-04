module JsonWebToken
    SECRET_KEY = ENV.fetch('JWT_SECRET_KEY', 'default_fallback_secret')
end