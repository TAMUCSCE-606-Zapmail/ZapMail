Given("Slack notifications are spied") do
  @slack_spy = instance_spy("SlackNotifierService")
  allow(SlackNotifierService).to receive(:new).and_return(@slack_spy)
end

Given("a user exists with email {string}") do |email|
  @user = User.find_by(email: email)
  unless @user
    @user = User.create!(
      name: "Test User",
      email: email,
      password: "password",
      password_confirmation: "password"
    )
  end
end

Given("a template exists named {string}") do |template_name|
  @template = Template.find_by(name: template_name, user: @user)
  unless @template
    @template = Template.create!(
      name: template_name,
      user: @user,
      spreadsheet_url: "https://docs.google.com/spreadsheets/d/dummy_id/edit",
      rules_data: { "rules" => [] }.to_json
    )
  end
end


Given("I have an automation with a template and action data") do
  user = User.find_by(email: "test@example.com") || FactoryBot.create(:user, email: "test@example.com")
  template = Template.find_by(name: "TestTemplate") || FactoryBot.create(:template, name: "TestTemplate", user: user)

  @automation = Automation.create!(
    user: user,
    template: template,
    action_data: {
      'to' => 'recipient@example.com',
      'subject' => 'Hello',
      'body' => 'World'
    },
    send_at: 1.hour.from_now,
    status: 'scheduled',
    enabled: true
  )
end

Given("AI content generation is stubbed to raise an error") do
  ai_service = instance_double("AiContentService")
  allow(AiContentService).to receive(:new).and_return(ai_service)
  allow(ai_service).to receive(:generate).and_raise(StandardError.new("AI Failure"))
end

Given("sending email is stubbed to raise an error") do
    @job_should_fail = true
end

When("I perform the email sender job for that automation") do
    # Spy Slack for any scenario
    slack_spy = instance_spy("SlackNotifierService")
    allow(SlackNotifierService).to receive(:new).and_return(slack_spy)
    @slack_spy = slack_spy

    if @job_should_fail
        # Stub mailer to raise an exception to hit the outer rescue
        allow(AutomationMailer).to receive(:send_automation_email)
            .and_raise(StandardError, "Forced critical error")
        begin
            EmailSenderJob.new.perform(@automation.id)
        rescue StandardError
        end
    else
        EmailSenderJob.new.perform(@automation.id)
    end
end

Then("Slack should be notified of success") do
  expect(@slack_spy).to have_received(:notify).with(/Successfully sent email/, :success)
end

Then("Slack should be notified of AI failure") do
  expect(@slack_spy).to have_received(:notify).with(/AI content generation failed/, :warning)
end

Then("Slack should be notified of a critical error") do
  expect(@slack_spy).to have_received(:notify).with(/Email Sender Job Failed!/, :error)
end

Then("an email should be sent to the automation's recipient") do
  expect(ActionMailer::Base.deliveries.map(&:to).flatten).to include(@automation.action_data['to'])
end

Then("the automation's status should be {string}") do |status|
  expect(@automation.reload.status).to eq(status)
end
