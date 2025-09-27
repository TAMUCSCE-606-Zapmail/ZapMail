class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :mock_dev_user
  before_action :authenticate_user!
  include Pagy::Backend

  private

  def mock_dev_user
    if Rails.env.development?
      sign_in User.first || User.create!(email: "dev@example.com", password: "password")
    end
  end
end
