class SlackNotifierService
    def notify(message, status = :info)
      # If no webhook URL is configured, just log to the console and exit.
      # This prevents the app from crashing if Slack is not set up.
      unless $slack_notifier.endpoint.present?
        Rails.logger.info "Slack Notifier: #{message}"
        return
      end
  
      # Set the color of the message bar based on the status
      color = case status
              when :success then "good"
              when :error   then "danger"
              else "#439FE0" # A neutral blue for info
              end
  
      # Send a richly formatted message to Slack
      $slack_notifier.post text: message, attachments: [{
        color: color,
        ts: Time.current.to_i
      }]
    end
  end
  