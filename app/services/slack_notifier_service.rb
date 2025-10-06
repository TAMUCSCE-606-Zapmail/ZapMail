class SlackNotifierService
    # A map of statuses to their corresponding Slack color and icon
    STATUS_STYLES = {
      info:    { color: "#439FE0", icon: "ℹ️" },
      success: { color: "good",    icon: "✅" },
      warning: { color: "warning", icon: "⚠️" },
      error:   { color: "danger",  icon: "🚨" }
    }.freeze

    def notify(message, status = :info)
      # If no webhook URL is configured, just log to the console and exit.
      unless $slack_notifier.endpoint.present?
        Rails.logger.info "Slack Notifier (#{status}): #{message}"
        return
      end

      # Get the style from our map, defaulting to :info if the status is unknown
      style = STATUS_STYLES.fetch(status, STATUS_STYLES[:info])

      # Prepend the message with the appropriate icon
      formatted_message = "#{style[:icon]} #{message}"

      # Send a richly formatted message to Slack
      $slack_notifier.post text: formatted_message, attachments: [ {
        color: style[:color],
        ts: Time.current.to_i
      } ]
    end
end
