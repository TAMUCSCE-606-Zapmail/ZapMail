require 'rails_helper'

RSpec.describe Automation, type: :model do
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
      spreadsheet_url: 'https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit?gid=0#gid=0',
      rules_data: { columns: [], rules: [] }
    )
  end

  describe 'associations' do
    it 'belongs to template' do
      automation = Automation.new(
        user: user,
        template: template,
        status: 'scheduled',
        send_at: 1.hour.from_now,
        enabled: true,
        action_data: { to: 'test@example.com' }
      )

      expect(automation.template).to eq(template)
    end

    it 'belongs to user' do
      automation = Automation.new(
        user: user,
        template: template,
        status: 'scheduled',
        send_at: 1.hour.from_now,
        enabled: true,
        action_data: { to: 'test@example.com' }
      )

      expect(automation.user).to eq(user)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      automation = Automation.new(
        user: user,
        template: template,
        status: 'scheduled',
        send_at: 1.hour.from_now,
        enabled: true,
        action_data: { to: 'test@example.com', subject: 'Test', body: 'Body' }
      )
      expect(automation).to be_valid
    end

    it 'is invalid without status' do
      automation = Automation.new(
        user: user,
        template: template,
        status: nil,  # Explicitly set to nil
        send_at: 1.hour.from_now,
        enabled: true,
        action_data: { to: 'test@example.com' }
      )
      expect(automation).not_to be_valid
      expect(automation.errors[:status]).to include("can't be blank")
    end

    it 'is invalid without send_at' do
      automation = Automation.new(
        user: user,
        template: template,
        status: 'scheduled',
        enabled: true,
        action_data: { to: 'test@example.com' }
      )
      expect(automation).not_to be_valid
      expect(automation.errors[:send_at]).to include("can't be blank")
    end

    it 'is invalid without action_data' do
      automation = Automation.new(
        user: user,
        template: template,
        status: 'scheduled',
        send_at: 1.hour.from_now,
        enabled: true
      )
      expect(automation).not_to be_valid
      expect(automation.errors[:action_data]).to include("can't be blank")
    end
  end

  describe 'scopes' do
    let!(:scheduled_enabled) do
      user.automations.create!(
        template: template,
        status: 'scheduled',
        enabled: true,
        send_at: 3.hours.from_now,  # Most recent
        action_data: { to: 'test1@example.com' }
      )
    end

    let!(:scheduled_disabled) do
      user.automations.create!(
        template: template,
        status: 'scheduled',
        enabled: false,
        send_at: 2.hours.from_now,
        action_data: { to: 'test2@example.com' }
      )
    end

    let!(:completed_automation) do
      user.automations.create!(
        template: template,
        status: 'completed',
        enabled: true,
        send_at: 1.hour.ago,
        action_data: { to: 'test3@example.com' }
      )
    end

    let!(:failed_automation) do
      user.automations.create!(
        template: template,
        status: 'failed',
        enabled: true,
        send_at: 3.hours.ago,  # Oldest
        action_data: { to: 'test4@example.com' }
      )
    end

    let!(:due_automation) do
      user.automations.create!(
        template: template,
        status: 'scheduled',
        enabled: true,
        send_at: 1.minute.ago,
        action_data: { to: 'test5@example.com' }
      )
    end

    describe '.scheduled' do
      it 'returns only scheduled and enabled automations' do
        result = Automation.scheduled
        expect(result).to include(scheduled_enabled, due_automation)
        expect(result).not_to include(scheduled_disabled, completed_automation, failed_automation)
      end
    end

    describe '.due_to_run' do
      it 'returns only scheduled automations that should run now' do
        result = Automation.due_to_run
        expect(result).to include(due_automation)
        expect(result).not_to include(scheduled_enabled, completed_automation, failed_automation)
      end
    end

    describe '.completed' do
      it 'returns only completed automations' do
        result = Automation.completed
        expect(result).to eq([ completed_automation ])
      end
    end

    describe '.failed' do
      it 'returns only failed automations' do
        result = Automation.failed
        expect(result).to eq([ failed_automation ])
      end
    end

    describe '.recent' do
      it 'orders automations by send_at descending' do
        result = Automation.recent
        expect(result.first).to eq(scheduled_enabled)  # 3 hours from now (most recent)
        expect(result.last).to eq(failed_automation)   # 3 hours ago (oldest)
      end
    end

    describe '.for_user' do
      let(:other_user) do
        User.create!(
          name: 'Other User',
          email: 'other@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        )
      end

      let(:other_template) do
        other_user.templates.create!(
          name: 'Other Template',
          spreadsheet_url: 'https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit?gid=0#gid=0',
          rules_data: { columns: [], rules: [] }
        )
      end

      let!(:other_automation) do
        other_user.automations.create!(
          template: other_template,
          status: 'scheduled',
          enabled: true,
          send_at: 1.hour.from_now,
          action_data: { to: 'other@example.com' }
        )
      end

      it 'returns automations for specific user only' do
        result = Automation.for_user(user)
        expect(result).to include(scheduled_enabled, completed_automation, failed_automation)
        expect(result).not_to include(other_automation)
      end
    end
  end

  describe '#executed?' do
    it 'returns true for completed status' do
      automation = user.automations.create!(
        template: template,
        status: 'completed',
        send_at: 1.hour.ago,
        enabled: true,
        action_data: { to: 'test@example.com' }
      )
      expect(automation.executed?).to be true
    end

    it 'returns true for failed status' do
      automation = user.automations.create!(
        template: template,
        status: 'failed',
        send_at: 1.hour.ago,
        enabled: true,
        action_data: { to: 'test@example.com' }
      )
      expect(automation.executed?).to be true
    end

    it 'returns false for scheduled status' do
      automation = user.automations.create!(
        template: template,
        status: 'scheduled',
        send_at: 1.hour.from_now,
        enabled: true,
        action_data: { to: 'test@example.com' }
      )
      expect(automation.executed?).to be false
    end
  end

  describe '#executed_at' do
    it 'returns updated_at when executed' do
      automation = user.automations.create!(
        template: template,
        status: 'completed',
        send_at: 1.hour.ago,
        enabled: true,
        action_data: { to: 'test@example.com' }
      )
      expect(automation.executed_at).to eq(automation.updated_at)
    end

    it 'returns nil when not executed' do
      automation = user.automations.create!(
        template: template,
        status: 'scheduled',
        send_at: 1.hour.from_now,
        enabled: true,
        action_data: { to: 'test@example.com' }
      )
      expect(automation.executed_at).to be_nil
    end
  end
end
