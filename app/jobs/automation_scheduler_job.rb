class AutomationSchedulerJob
    include Sidekiq::Job
  
    def perform
      slack_notifier = SlackNotifierService.new
      
      # Send a quiet log message to Slack just to show the job is running.
      # This acts as a "heartbeat" for your system.
      slack_notifier.notify("Scheduler check for due automations started.")
  
      due_automations = Automation.due_to_run
  
      # If no jobs are due, we don't need to send another notification.
      # The initial "heartbeat" is enough.
      return if due_automations.empty?
  
      # If jobs ARE found, send a success message with the count.
      slack_notifier.notify(
        "Found #{due_automations.count} automations to process. Enqueuing now...",
        :success
      )
  
      due_automations.find_each do |automation|
        # Immediately mark the job as 'processing' to prevent race conditions.
        automation.update!(status: 'processing')
        
        # Enqueue the actual email sending job.
        EmailSenderJob.perform_async(automation.id)
      end
  
    rescue StandardError => e
      # --- Send a critical ERROR log if the scheduler job itself fails ---
      # This is a high-priority alert because it means no jobs can be scheduled.
      error_message = <<~MSG
        *Automation Scheduler Job Failed!*
        The scheduler crashed and is unable to enqueue new jobs. This requires immediate attention.
        *Error:* `#{e.message}`
      MSG
      slack_notifier.notify(error_message, :error)
      raise e
    end
  end
  