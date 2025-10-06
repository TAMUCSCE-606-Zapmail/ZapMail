class ApplicationController < ActionController::Base
  # Protect from CSRF attacks
  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  helper_method :current_user, :logged_in?

  # --- FIX: Global Error Handler with Slack Notification ---
  # This block will rescue any unhandled exception that occurs in any controller,
  # send a detailed error message to Slack, and then render a user-friendly error page.
  rescue_from StandardError do |exception|
    # Log the full error to the standard Rails logger for detailed debugging
    Rails.logger.error("Unhandled Exception: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))

    # Send a high-alert notification to Slack
    error_message = <<~MSG
      *Unhandled Exception in Web Request!*
      *Error:* `#{exception.class}: #{exception.message}`
      *URL:* `#{request.method.upcase} #{request.original_url}`
      *User:* `#{current_user&.email || 'Not logged in'}`
    MSG
    SlackNotifierService.new.notify(error_message, :error)

    # Render a generic, user-friendly error page instead of crashing
    render "errors/internal_server_error", status: :internal_server_error
  end

  private

  # --- JWT Token Handling ---

  def encode_token(payload)
    payload[:exp] = 24.hours.from_now.to_i
    # Note: For production, your JWT_SECRET_KEY should be set as a Heroku Config Var
    JWT.encode(payload, ENV.fetch("JWT_SECRET_KEY"))
  end

  def decoded_token
    auth_header = request.headers["Authorization"]
    token = if auth_header
              auth_header.split(" ").last
    else
              cookies[:jwt]
    end

    if token
      begin
        JWT.decode(token, ENV.fetch("JWT_SECRET_KEY"), true, algorithm: "HS256")
      rescue JWT::DecodeError
        nil
      end
    end
  end

  # --- User Session Management ---

  def current_user
    if decoded_token
      user_id = decoded_token[0]["user_id"]
      @current_user ||= User.find_by(id: user_id)
    end
  end

  def logged_in?
    !!current_user
  end

  def authorize
    unless logged_in?
      # --- FIX: Send a warning notification to Slack on authorization failure ---
      warning_message = <<~MSG
        *Authorization Failure*
        An unauthenticated user tried to access a protected page: `#{request.method.upcase} #{request.original_url}`
      MSG
      SlackNotifierService.new.notify(warning_message, :warning)

      flash[:error] = "You must be logged in to access this page."
      redirect_to login_url
    end
  end
end
