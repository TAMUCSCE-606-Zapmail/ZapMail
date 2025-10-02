require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it 'has many templates' do
      user = User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      
      template = user.templates.create!(
        name: 'Test Template',
        spreadsheet_url: 'https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit?gid=0#gid=0',
        rules_data: { columns: [], rules: [] }
      )
      
      expect(user.templates).to include(template)
    end

    it 'has many automations' do
      user = User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      
      template = user.templates.create!(
        name: 'Test Template',
        spreadsheet_url: 'https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit?gid=0#gid=0',
        rules_data: { columns: [], rules: [] }
      )
      
      automation = user.automations.create!(
        template: template,
        status: 'scheduled',
        send_at: 1.hour.from_now,
        enabled: true,
        action_data: { to: 'test@example.com', subject: 'Test', body: 'Body' }
      )
      
      expect(user.automations).to include(automation)
    end

    it 'destroys associated automations when user is destroyed' do
      user = User.create!(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      
      template = user.templates.create!(
        name: 'Test Template',
        spreadsheet_url: 'https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit?gid=0#gid=0',
        rules_data: { columns: [], rules: [] }
      )
      
      automation = user.automations.create!(
        template: template,
        status: 'scheduled',
        send_at: 1.hour.from_now,
        enabled: true,
        action_data: { to: 'test@example.com', subject: 'Test', body: 'Body' }
      )
      
      automation_id = automation.id
      
      expect { user.destroy }.to change { Automation.count }.by(-1)
      expect(Automation.find_by(id: automation_id)).to be_nil
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      user = User.new(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user).to be_valid
    end

    it 'is invalid without a name' do
      user = User.new(
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it 'is invalid without an email' do
      user = User.new(
        name: 'Test User',
        password: 'password123',
        password_confirmation: 'password123'
      )
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end
  end
end