class EmailSenderJob
    include Sidekiq::Job
  
    def perform(automation_id)
      automation = Automation.find(automation_id)
      # FIX: Get the user who created the automation
      user = automation.user
      action_data = automation.action_data
      
      # FIX: The 'scheduling_options' variable is removed as it is no longer being saved by the controller.
      # This was the source of the "undefined method '[]' for nil" error.
      # scheduling_options = action_data['scheduling_options']
  
      # 1. Generate AI Content
      ai_service = AiContentService.new
      generated_content = ai_service.generate(
        subject: action_data['subject'],
        body: action_data['body']
      )
  
      # 2. Send the Email, now passing the user object
      AutomationMailer.send_automation_email(
        user: user, # Pass the user to the mailer
        to: action_data['to'],
        subject: generated_content[:subject],
        body: generated_content[:body]
      ).deliver_now
  
      # 3. Update Automation Status
      # FIX: The complex repeating logic has been replaced with the simple, correct
      # logic for a one-time job. This will resolve the error.
      automation.update!(enabled: false, status: 'sent')
  
    rescue StandardError => e
      # If anything goes wrong, log the error and mark the job as failed
      automation.update!(status: 'failed', error_message: e.message)
      Rails.logger.error "Failed to send automation email for ID #{automation_id}: #{e.message}"
    end
  end
  