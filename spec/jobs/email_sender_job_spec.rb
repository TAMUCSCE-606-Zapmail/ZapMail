require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe EmailSenderJob, type: :job do
  # Use fake mode to test job enqueueing without actually running jobs
  Sidekiq::Testing.fake!

  let(:user) do
    User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  let(:template) do
    user.templates.create!(
      name: 'Test Template',
      spreadsheet_url: 'https://docs.google.com/spreadsheets/d/test',
      rules_data: { columns: [], rules: [] }
    )
  end

  let(:automation) do
    user.automations.create!(
      template: template,
      status: 'processing',
      send_at: 1.hour.ago,
      enabled: true,
      action_data: {
        to: 'recipient@example.com',
        subject: 'Test Subject',
        body: 'Test Body'
      }
    )
  end

  describe '#perform' do
    let(:slack_service) { instance_double(SlackNotifierService) }
    let(:ai_service) { instance_double(AiContentService) }

    before do
      allow(SlackNotifierService).to receive(:new).and_return(slack_service)
      allow(AiContentService).to receive(:new).and_return(ai_service)
      allow(slack_service).to receive(:notify)
    end

    context 'when email sends successfully' do
      before do
        allow(ai_service).to receive(:generate).and_return({
          subject: 'AI Generated Subject',
          body: 'AI Generated Body'
        })
        
        # Mock the mailer
        mailer_double = double('mailer')
        allow(AutomationMailer).to receive(:send_automation_email).and_return(mailer_double)
        allow(mailer_double).to receive(:deliver_now)
      end

      it 'finds the automation' do
        expect(Automation).to receive(:find).with(automation.id).and_return(automation)
        EmailSenderJob.new.perform(automation.id)
      end

      it 'sends start notification to Slack' do
        expect(slack_service).to receive(:notify).with(
          "Starting email job for Template '#{template.name}' (Automation ID: #{automation.id})."
        )
        EmailSenderJob.new.perform(automation.id)
      end

      it 'generates AI content' do
        expect(ai_service).to receive(:generate).with(
          subject: 'Test Subject',
          body: 'Test Body'
        )
        EmailSenderJob.new.perform(automation.id)
      end

      it 'sends email with AI-generated content' do
        expect(AutomationMailer).to receive(:send_automation_email).with(
          user: user,
          to: 'recipient@example.com',
          subject: 'AI Generated Subject',
          body: 'AI Generated Body'
        ).and_call_original
        
        EmailSenderJob.new.perform(automation.id)
      end

      it 'updates automation status to completed' do
        EmailSenderJob.new.perform(automation.id)
        automation.reload
        expect(automation.status).to eq('completed')
        expect(automation.enabled).to be false
      end

      it 'sends success notification to Slack' do
        expect(slack_service).to receive(:notify).with(
          "Successfully sent email for Template '#{template.name}' to recipient@example.com.",
          :success
        )
        EmailSenderJob.new.perform(automation.id)
      end
    end

    context 'when AI service fails' do
      before do
        allow(ai_service).to receive(:generate).and_raise(StandardError, 'API timeout')
        
        # Mock the mailer
        mailer_double = double('mailer')
        allow(AutomationMailer).to receive(:send_automation_email).and_return(mailer_double)
        allow(mailer_double).to receive(:deliver_now)
      end

      it 'sends warning notification to Slack' do
        expect(slack_service).to receive(:notify).with(
          /AI content generation failed for Automation ID: #{automation.id}.*API timeout/m,
          :warning
        )
        EmailSenderJob.new.perform(automation.id)
      end

      it 'falls back to original content' do
        expect(AutomationMailer).to receive(:send_automation_email).with(
          user: user,
          to: 'recipient@example.com',
          subject: 'Test Subject',
          body: 'Test Body'
        ).and_call_original
        
        EmailSenderJob.new.perform(automation.id)
      end

      it 'still completes the automation successfully' do
        EmailSenderJob.new.perform(automation.id)
        automation.reload
        expect(automation.status).to eq('completed')
      end
    end

    context 'when email delivery fails' do
      before do
        allow(ai_service).to receive(:generate).and_return({
          subject: 'AI Subject',
          body: 'AI Body'
        })
        
        # Mock mailer to raise an error
        mailer_double = double('mailer')
        allow(AutomationMailer).to receive(:send_automation_email).and_return(mailer_double)
        allow(mailer_double).to receive(:deliver_now).and_raise(StandardError, 'SMTP connection failed')
      end

      it 'updates automation status to failed' do
        expect {
          EmailSenderJob.new.perform(automation.id)
        }.to raise_error(StandardError)
        
        automation.reload
        expect(automation.status).to eq('failed')
        expect(automation.error_message).to eq('SMTP connection failed')
      end

      it 'sends error notification to Slack' do
        expect(slack_service).to receive(:notify).with(
          /Email Sender Job Failed!.*SMTP connection failed/m,
          :error
        )
        
        expect {
          EmailSenderJob.new.perform(automation.id)
        }.to raise_error(StandardError)
      end

      it 're-raises the error for Sidekiq retry' do
        expect {
          EmailSenderJob.new.perform(automation.id)
        }.to raise_error(StandardError, 'SMTP connection failed')
      end
    end

    context 'when automation is not found' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect {
          EmailSenderJob.new.perform(999999)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'integration test with real mailer' do
      before do
        # Use ActionMailer test mode
        ActionMailer::Base.delivery_method = :test
        ActionMailer::Base.perform_deliveries = true
        ActionMailer::Base.deliveries.clear
        
        allow(ai_service).to receive(:generate).and_return({
          subject: 'Test AI Subject',
          body: 'Test AI Body'
        })
      end

      it 'delivers the email' do
        expect {
          EmailSenderJob.new.perform(automation.id)
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it 'sends email to correct recipient' do
        EmailSenderJob.new.perform(automation.id)
        
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include('recipient@example.com')
        expect(email.from).to include('test@example.com')
        expect(email.subject).to eq('Test AI Subject')
      end
    end
  end

  describe 'job enqueueing' do
    it 'enqueues the job with correct arguments' do
      expect {
        EmailSenderJob.perform_async(automation.id)
      }.to change(EmailSenderJob.jobs, :size).by(1)
      
      expect(EmailSenderJob.jobs.last['args']).to eq([automation.id])
    end

    it 'uses the default queue' do
      EmailSenderJob.perform_async(automation.id)
      expect(EmailSenderJob.jobs.last['queue']).to eq('default')
    end
  end

  describe 'error handling scenarios' do
    let(:slack_service) { instance_double(SlackNotifierService) }
    
    before do
      allow(SlackNotifierService).to receive(:new).and_return(slack_service)
      allow(slack_service).to receive(:notify)
    end

    context 'when user is deleted before job runs' do
      before do
        automation.user.destroy
      end

      it 'raises an error' do
        expect {
          EmailSenderJob.new.perform(automation.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when template is deleted before job runs' do
      before do
        automation.template.destroy
      end

      it 'raises an error' do
        expect {
          EmailSenderJob.new.perform(automation.id)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when action_data is missing required fields' do
      before do
        automation.update!(action_data: {})
        
        ai_service = instance_double(AiContentService)
        allow(AiContentService).to receive(:new).and_return(ai_service)
        allow(ai_service).to receive(:generate).and_raise(StandardError, 'Missing subject')
      end

      it 'marks automation as failed' do
        expect {
          EmailSenderJob.new.perform(automation.id)
        }.to raise_error(StandardError)
        
        automation.reload
        expect(automation.status).to eq('failed')
      end
    end
  end
end