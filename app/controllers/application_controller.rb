class ApplicationController < ActionController::Base
  # Restrict access to modern browsers (Rails security feature)
  allow_browser versions: :modern

  # Automatically log in a dev user when in development mode
  before_action :mock_dev_user

  # Require user authentication for all controllers
  before_action :authenticate_user!

  # Ensure Devise accepts custom parameters (like :name)
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  # -------------------------------
  # Mock a default user in development
  # -------------------------------
  def mock_dev_user
    if Rails.env.development?
      # Sign in the first user if exists, otherwise create one
      sign_in User.first || User.create!(
        email: "dev@example.com",
        password: "password",
        name: "Dev User" # Added name for testing profile page
      )
    end
  end

  # -------------------------------
  # Permit extra Devise parameters
  # -------------------------------
  def configure_permitted_parameters
    # Allow :name when signing up
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])

    # Allow :name when updating account (profile page)
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
