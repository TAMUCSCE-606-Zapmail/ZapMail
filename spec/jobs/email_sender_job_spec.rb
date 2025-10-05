require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe EmailSenderJob, type: :job do
  Sidekiq::Testing.fake!

  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:template) { user.templates.create!(name: 'Test Template', spreadsheet_url: 'https://docs.google.com/spreadsheets/d/test', rules_data: { columns: [], rules: [] }) }
  let(:automation) { user.automations.create!(template: template, status: 'processing', send_at: 1.hour.ago, enabled: true, action_data: { to: 'recipient@example.com', subject: 'Test Subject', body: 'Test Body' }) }
  let(:slack_service) { instance_double(SlackNotifierService) }
  let(:ai_service) { instance_double(AiContentService) }
  let(:mailer_double) { double('mailer') }

  before do
    allow(SlackNotifierService).to receive(:new).and_return(slack_service)
    allow(AiContentService).to receive(:new).and_return(ai_service)
    allow(slack_service).to receive(:notify)
    allow(AutomationMailer).to receive(:send_automation_email).and_return(mailer_double)
  end

  describe '#perform' do
    context 'successful email send' do
      before do
        allow(ai_service).to receive(:generate).and_return({ subject: 'AI Subject', body: 'AI Body' })
        allow(mailer_double).to receive(:deliver_now)
      end

      it 'sends email and completes automation' do
        expect(slack_service).to receive(:notify).with(/Starting email job/)
        expect(slack_service).to receive(:notify).with(/Successfully sent email/, :success)
        EmailSenderJob.new.perform(automation.id)
        automation.reload
        expect(automation.status).to eq('completed')
        expect(automation.enabled).to be false
      end

      it 'uses AI-generated content' do
        expect(AutomationMailer).to receive(:send_automation_email).with(hash_including(subject: 'AI Subject', body: 'AI Body'))
        EmailSenderJob.new.perform(automation.id)
      end
    end

    context 'AI service fails' do
      before do
        allow(ai_service).to receive(:generate).and_raise(StandardError, 'API timeout')
        allow(mailer_double).to receive(:deliver_now)
      end

      it 'falls back to original content' do
        expect(slack_service).to receive(:notify).with(/AI content generation failed/, :warning)
        expect(AutomationMailer).to receive(:send_automation_email).with(hash_including(subject: 'Test Subject', body: 'Test Body'))
        EmailSenderJob.new.perform(automation.id)
        expect(automation.reload.status).to eq('completed')
      end
    end

    context 'email delivery fails' do
      before do
        allow(ai_service).to receive(:generate).and_return({ subject: 'AI', body: 'Body' })
        allow(mailer_double).to receive(:deliver_now).and_raise(StandardError, 'SMTP failed')
      end

      it 'marks as failed and re-raises error' do
        expect(slack_service).to receive(:notify).with(/Email Sender Job Failed!/, :error)
        expect { EmailSenderJob.new.perform(automation.id) }.to raise_error(StandardError, 'SMTP failed')
        expect(automation.reload.status).to eq('failed')
        expect(automation.error_message).to eq('SMTP failed')
      end
    end

    it 'raises error for missing automation' do
      expect { EmailSenderJob.new.perform(999999) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'handles nil automation gracefully' do
      allow(Automation).to receive(:find).and_return(nil)
      expect(slack_service).to receive(:notify).with(/not found/, :warning)
      expect { EmailSenderJob.new.perform(999) }.not_to raise_error
    end
  end

  describe 'job enqueueing' do
    it 'enqueues with correct args' do
      expect { EmailSenderJob.perform_async(automation.id) }.to change(EmailSenderJob.jobs, :size).by(1)
      expect(EmailSenderJob.jobs.last['args']).to eq([automation.id])
    end
  end

  describe 'integration test' do
    before do
      ActionMailer::Base.delivery_method = :test
      ActionMailer::Base.deliveries.clear
      allow(ai_service).to receive(:generate).and_return({ subject: 'AI Subject', body: 'AI Body' })
      allow(AutomationMailer).to receive(:send_automation_email).and_call_original
    end

    it 'delivers real email' do
      expect { EmailSenderJob.new.perform(automation.id) }.to change { ActionMailer::Base.deliveries.count }.by(1)
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include('recipient@example.com')
      expect(email.from).to include('test@example.com')
    end
  end
end