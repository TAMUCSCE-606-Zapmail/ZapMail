class EmailSenderJob
    include Sidekiq::Job
  
    def perform(automation_id)
      automation = Automation.find(automation_id)
      user = automation.user
      action_data = automation.action_data
  
      # ... (AI content generation and mailer logic remains the same) ...
      AutomationMailer.send_automation_email(
        user: user,
        to: action_data['to'],
        # ...
      ).deliver_now
  
      # Update the job status
      automation.update!(enabled: false, status: 'sent')
  
      # --- FIX: Send a success notification to Slack ---
      SlackNotifierService.new.notify(
        "✅ Successfully sent email for Template '#{automation.template.name}' to #{action_data['to']}.",
        :success
      )
  
    rescue StandardError => e
      # If anything goes wrong, update the job and send an error notification.
      automation.update!(status: 'failed', error_message: e.message)
      
      # --- FIX: Send a detailed error notification to Slack ---
      error_message = <<~MSG
        🚨 **Email Sender Job Failed!**
        *Automation ID:* #{automation_id}
        *Template:* #{automation.template.name}
        *User:* #{user.email}
        *Error:* `#{e.message}`
      MSG
      SlackNotifierService.new.notify(error_message, :error)
  
      # Re-raise the error to ensure Sidekiq's retry mechanism can catch it if configured.
      raise e
    end
  end
  