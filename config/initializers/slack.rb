# This initializer makes the Slack webhook URL available globally.
# It uses the environment variable we set in the previous step.
$slack_notifier = Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL']) do
    defaults channel: (Rails.env.development? ? "#development" : "#production"),
             username: "ZapMail Bot"
  end
  