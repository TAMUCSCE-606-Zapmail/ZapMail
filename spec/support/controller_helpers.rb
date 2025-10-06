# spec/support/controller_helpers.rb
module ControllerHelpers
  def sign_in(user)
    token = controller.send(:encode_token, { user_id: user.id })
    cookies[:jwt] = token
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in?).and_return(true)
  end

  def stub_slack_notifications
    slack_service = instance_double(SlackNotifierService)
    allow(SlackNotifierService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:notify)
    slack_service
  end
end

RSpec.configure do |config|
  config.include ControllerHelpers, type: :controller
end
