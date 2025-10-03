class AutomationSchedulerJob
    include Sidekiq::Job
  
    def perform
      # Log that the job has started. This confirms that sidekiq-cron is working.
      Rails.logger.info "--- AutomationSchedulerJob: Starting check for due automations ---"
  
      # Find all automations that are enabled and due to be sent.
      due_automations = Automation.due_to_run
  
      # If no jobs are found, log that and exit. This is very useful for debugging.
      if due_automations.empty?
        Rails.logger.info "AutomationSchedulerJob: No automations are due to run at this time."
        return
      end
  
      # If jobs are found, log how many were discovered.
      Rails.logger.info "AutomationSchedulerJob: Found #{due_automations.count} automations to schedule."
  
      due_automations.find_each do |automation|
        # Log which specific automation is being processed.
        Rails.logger.info "--> Processing Automation ID: #{automation.id}"
  
        # Mark the job as 'processing' to prevent it from being picked up again.
        automation.update!(status: 'processing')
        
        # Log that the email sending job is being enqueued.
        Rails.logger.info "--> Enqueuing EmailSenderJob for Automation ID: #{automation.id}"
        EmailSenderJob.perform_async(automation.id)
      end
      
      Rails.logger.info "--- AutomationSchedulerJob: Finished scheduling ---"
    end
  end