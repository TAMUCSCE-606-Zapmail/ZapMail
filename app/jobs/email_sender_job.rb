class EmailSenderJob
    include Sidekiq::Job
  
    def perform(automation_id)
      automation = Automation.find(automation_id)
      # FIX: Get the user who created the automation
      user = automation.user
      action_data = automation.action_data
      scheduling_options = action_data['scheduling_options']
  
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
  
      # 3. Update Automation Status and Reschedule if necessary
      if scheduling_options['is_repeating']
        deadline = scheduling_options['deadline'].present? ? Date.parse(scheduling_options['deadline']) : nil
        
        if deadline && Date.current > deadline
          automation.update!(enabled: false, status: 'completed')
        else
          next_send_at = case scheduling_options['frequency']
                         when 'daily'
                           1.day.from_now
                         when 'weekly'
                           1.week.from_now
                         end
          automation.update!(send_at: next_send_at, status: 'scheduled')
        end
      else
        automation.update!(enabled: false, status: 'sent')
      end
  
    rescue StandardError => e
      automation.update!(status: 'failed', error_message: e.message)
      Rails.logger.error "Failed to send automation email for ID #{automation_id}: #{e.message}"
    end
  end
  