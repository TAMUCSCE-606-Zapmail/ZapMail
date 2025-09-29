# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # Protect from CSRF attacks, but use null_session for API-style token auth
  protect_from_forgery with: :null_session

  helper_method :current_user, :logged_in?

  private

  # --- JWT Token Handling ---

  def encode_token(payload)
    # Set token to expire in 24 hours
    payload[:exp] = 24.hours.from_now.to_i
    JWT.encode(payload, JsonWebToken::SECRET_KEY)
  end

  def decoded_token
    # Get token from the Authorization header or cookies
    auth_header = request.headers['Authorization']
    if auth_header
      token = auth_header.split(' ').last
    else
      token = cookies[:jwt]
    end

    if token
      begin
        JWT.decode(token, JsonWebToken::SECRET_KEY, true, algorithm: 'HS256')
      rescue JWT::DecodeError
        nil
      end
    end
  end

  # --- User Session Management ---

  def current_user
    if decoded_token
      user_id = decoded_token[0]['user_id']
      @current_user ||= User.find_by(id: user_id)
    end
  end

  def logged_in?
    !!current_user
  end

  def authorize
    unless logged_in?
      flash[:error] = "You must be logged in to access this page."
      redirect_to login_url
    end
  end
end
