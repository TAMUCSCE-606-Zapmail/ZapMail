require 'rails_helper'

RSpec.describe AutomationsController, type: :controller do
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
      spreadsheet_url: 'https://example.com/sheet',
      rules_data: { columns: [], rules: [] }
    )
  end

  let!(:automation) do
    user.automations.create!(
      template: template,
      status: 'completed',
      send_at: 1.hour.ago,
      enabled: true,
      action_data: { to: 'test@example.com' }
    )
  end

  let(:slack_service) { instance_double(SlackNotifierService) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(SlackNotifierService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:notify)
  end

  describe 'GET #index' do
    it 'assigns paginated automations' do
      get :index
      expect(assigns(:automations).to_a).to include(automation)
      expect(response).to be_successful
    end

    it 'filters by status' do
      get :index, params: { status: 'completed' }
      expect(assigns(:automations).to_a).to include(automation)
    end
  end

  describe 'GET #show' do
    it 'shows automation' do
      get :show, params: { id: automation.id }
      expect(assigns(:automation)).to eq(automation)
      expect(response).to be_successful
    end

    it 'handles not found with Slack notification' do
      expect(slack_service).to receive(:notify).with(/Record Not Found/, :warning)
      get :show, params: { id: 99999 }
      expect(response).to redirect_to(automations_path)
      expect(flash[:error]).to be_present
    end
  end
end
