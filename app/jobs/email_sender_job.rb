class EmailSenderJob
    include Sidekiq::Job

    def perform(automation_id)
      automation = Automation.find(automation_id)
      if automation.nil?
        SlackNotifierService.new.notify(
          "Automation ID #{automation_id} not found. Skipping job.",
          :warning
        )
        return
      end
      user = automation.user
      action_data = automation.action_data

      slack_notifier = SlackNotifierService.new

      # Send an INFO log to show the job has started.
      slack_notifier.notify(
        "Starting email job for Template '#{automation.template.name}' (Automation ID: #{automation_id})."
      )

      begin
        # 1. Generate AI Content
        ai_service = AiContentService.new
        generated_content = ai_service.generate(
          subject: action_data["subject"],
          body: action_data["body"]
        )
      rescue StandardError => e
        # Send a WARNING log if the AI fails, then fall back to the original content.
        slack_notifier.notify(
          "AI content generation failed for Automation ID: #{automation_id}. Falling back to original content. Error: `#{e.message}`",
          :warning
        )
        generated_content = { subject: action_data["subject"], body: action_data["body"] }
      end

      # 2. Send the Email
      AutomationMailer.send_automation_email(
        user: user,
        to: action_data["to"],
        subject: generated_content[:subject],
        body: generated_content[:body]
      ).deliver_now

      # 3. Update the job status for a one-time job.
      automation.update!(enabled: false, status: "completed")

      # Send a SUCCESS log to show the job is complete.
      slack_notifier.notify(
        "Successfully sent email for Template '#{automation.template.name}' to #{action_data['to']}.",
        :success
      )

    rescue StandardError => e
      # If anything else goes wrong, update the job and send a critical ERROR log.
      automation.update!(status: "failed", error_message: e.message)

      error_message = <<~MSG
        *Email Sender Job Failed!*
        *Automation ID:* #{automation_id}
        *Template:* #{automation.template.name}
        *User:* #{user.email}
        *Error:* `#{e.message}`
      MSG
      slack_notifier.notify(error_message, :error)

      # Re-raise the error so Sidekiq can handle retries if configured.
      raise e
    end
end
