require 'rails_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!
RSpec.describe AutomationSchedulerJob, type: :job do
  include ActiveJob::TestHelper

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

  describe '#perform' do
    context 'with automations due to run' do
      let!(:due_automation) do
        user.automations.create!(
          template: template,
          status: 'scheduled',
          send_at: 5.minutes.ago,
          enabled: true,
          action_data: { to: 'recipient@example.com', subject: 'Test Subject' }
        )
      end

      let!(:future_automation) do
        user.automations.create!(
          template: template,
          status: 'scheduled',
          send_at: 1.hour.from_now,
          enabled: true,
          action_data: { to: 'future@example.com', subject: 'Future Email' }
        )
        end

        it 'enqueues EmailSenderJob for due automations' do
            expect {
            AutomationSchedulerJob.new.perform
            }.to change(EmailSenderJob.jobs, :size).by(1)

            expect(EmailSenderJob.jobs.last['args']).to include(due_automation.id)
        end

      it 'does not enqueue EmailSenderJob for future automations' do
        expect {
          AutomationSchedulerJob.new.perform
        }.not_to have_enqueued_job(EmailSenderJob).with(future_automation.id)
      end

      it 'updates automation status to processing' do
        AutomationSchedulerJob.new.perform
        expect(due_automation.reload.status).to eq('processing')
      end

      it 'sends Slack info notification' do
        slack_service = instance_double(SlackNotifierService)
        allow(SlackNotifierService).to receive(:new).and_return(slack_service)
        expect(slack_service).to receive(:notify).with(
          "Found 1 automations to process. Enqueuing now...", :success
        )

        AutomationSchedulerJob.new.perform
      end
    end

    context 'with no automations due' do
      it 'does not enqueue any jobs' do
        expect {
          AutomationSchedulerJob.new.perform
        }.not_to have_enqueued_job(EmailSenderJob)
      end

      it 'sends Slack info notification with zero count' do
        slack_service = instance_double(SlackNotifierService)
        allow(SlackNotifierService).to receive(:new).and_return(slack_service)
        expect(slack_service).to receive(:notify).with(
          "Scheduler check for due automations started."
        )

        AutomationSchedulerJob.new.perform
      end
    end

    context 'with disabled automations' do
      let!(:disabled_automation) do
        user.automations.create!(
          template: template,
          status: 'scheduled',
          send_at: 5.minutes.ago,
          enabled: false,
          action_data: { to: 'disabled@example.com' }
        )
      end

      it 'does not enqueue job for disabled automations' do
        expect {
          AutomationSchedulerJob.new.perform
        }.not_to have_enqueued_job(EmailSenderJob)
      end
    end

    context 'with multiple due automations' do
      before do
        3.times do |i|
          user.automations.create!(
            template: template,
            status: 'scheduled',
            send_at: 10.minutes.ago,
            enabled: true,
            action_data: { to: "recipient#{i}@example.com" }
          )
        end
      end

      it 'enqueues jobs for all due automations' do
        expect {
          AutomationSchedulerJob.new.perform
        }.to have_enqueued_job(EmailSenderJob).exactly(3).times
      end

      it 'sends correct count in Slack notification' do
        slack_service = instance_double(SlackNotifierService)
        allow(SlackNotifierService).to receive(:new).and_return(slack_service)
        expect(slack_service).to receive(:notify).with(
          "Scheduling 3 automation(s) for execution."
        )

        AutomationSchedulerJob.new.perform
      end
    end

    context 'when an error occurs' do
      before do
        allow(Automation).to receive(:due_to_run).and_raise(StandardError, 'Database error')
      end

      it 'sends error notification to Slack' do
        slack_service = instance_double(SlackNotifierService)
        allow(SlackNotifierService).to receive(:new).and_return(slack_service)
        expect(slack_service).to receive(:notify).with(
          /❌ AutomationSchedulerJob failed:.*Database error/m,
          :error
        )

        expect {
          AutomationSchedulerJob.new.perform
        }.to raise_error(StandardError)
      end
    end
  end
end