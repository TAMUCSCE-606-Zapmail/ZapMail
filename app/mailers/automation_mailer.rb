class EmailSenderJob
    include Sidekiq::Job
  
    def perform(automation_id)
      # ... setup ...
      slack_notifier = SlackNotifierService.new
      slack_notifier.notify("Starting email job...")
  
      # ... AI generation logic ...
  
      # --- THE ACTION: Use the Mailer as a tool ---
      AutomationMailer.send_automation_email(
        user: user,
        to: action_data['to'],
        # ...
      ).deliver_now
  
      # --- LOGGING STEP: Announce the success of the task ---
      automation.update!(enabled: false, status: 'sent')
      slack_notifier.notify(
        "✅ Successfully sent email for Template '#{automation.template.name}'...",
        :success
      )
  
    rescue StandardError => e
      # --- LOGGING STEP: Announce the failure of the task ---
      automation.update!(status: 'failed', error_message: e.message)
      slack_notifier.notify("🚨 Email Sender Job Failed! ...", :error)
      raise e
    end
  end
  