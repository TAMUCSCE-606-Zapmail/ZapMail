class AutomationMailer < ApplicationMailer
    # This default is now just a fallback.
    default from: "notifications@example.com"

    # FIX: The method now accepts a 'user' object.
    def send_automation_email(user:, to:, subject:, body:)
      @body = body

      # Set the 'from' address directly to the user's email.
      mail(from: user.email, to: to, subject: subject)
    end
end
