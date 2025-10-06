# This initializer makes the Slack webhook URL available globally.
# It uses the environment variable we set in the previous step.

if ENV["SLACK_WEBHOOK_URL"].present?
  $slack_notifier = Slack::Notifier.new(ENV["SLACK_WEBHOOK_URL"]) do
    defaults channel: (Rails.env.development? ? "#development" : "#production"),
             username: "ZapMail Bot"
  end
else
  Rails.logger.warn("⚠️ SLACK_WEBHOOK_URL not set — skipping Slack notifier initialization.")
end
