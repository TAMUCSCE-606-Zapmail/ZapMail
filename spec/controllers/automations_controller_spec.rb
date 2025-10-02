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
      spreadsheet_url: 'https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit?gid=0#gid=0',
      rules_data: { columns: [], rules: [] }
    )
  end

  let!(:automation1) do
    user.automations.create!(
      template: template,
      status: 'completed',
      send_at: 2.hours.ago,
      enabled: true,
      action_data: { to: 'test1@example.com' }
    )
  end

  let!(:automation2) do
    user.automations.create!(
      template: template,
      status: 'scheduled',
      send_at: 1.hour.from_now,
      enabled: true,
      action_data: { to: 'test2@example.com' }
    )
  end

  let!(:automation3) do
    user.automations.create!(
      template: template,
      status: 'failed',
      send_at: 3.hours.ago,
      enabled: true,
      action_data: { to: 'test3@example.com' }
    )
  end

  before do
    # Mock authentication
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in?).and_return(true)
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns @automations ordered by recent' do
      get :index
      expect(assigns(:automations)).to eq([automation2, automation1, automation3])
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end

    context 'with status filter' do
      it 'filters by completed status' do
        get :index, params: { status: 'completed' }
        expect(assigns(:automations)).to eq([automation1])
      end

      it 'filters by failed status' do
        get :index, params: { status: 'failed' }
        expect(assigns(:automations)).to eq([automation3])
      end

      it 'filters by scheduled status' do
        get :index, params: { status: 'scheduled' }
        expect(assigns(:automations)).to eq([automation2])
      end

      it 'shows all when status is "all"' do
        get :index, params: { status: 'all' }
        expect(assigns(:automations).count).to eq(3)
      end
    end

    it 'only shows current user automations' do
      other_user = User.create!(
        name: 'Other User',
        email: 'other@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      )
      other_template = other_user.templates.create!(
        name: 'Other Template',
        spreadsheet_url: 'https://docs.google.com/spreadsheets/d/other',
        rules_data: { columns: [], rules: [] }
      )
      other_automation = other_user.automations.create!(
        template: other_template,
        status: 'scheduled',
        send_at: 1.hour.from_now,
        enabled: true,
        action_data: { to: 'other@example.com' }
      )

      get :index
      expect(assigns(:automations)).not_to include(other_automation)
    end
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show, params: { id: automation1.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns @automation' do
      get :show, params: { id: automation1.id }
      expect(assigns(:automation)).to eq(automation1)
    end

    it 'renders the show template' do
      get :show, params: { id: automation1.id }
      expect(response).to render_template(:show)
    end

    context 'when automation does not exist' do
      it 'redirects to index with error' do
        get :show, params: { id: 99999 }
        expect(response).to redirect_to(automations_path)
        expect(flash[:error]).to eq("Automation not found")
      end
    end

    context 'when automation belongs to another user' do
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
          spreadsheet_url: 'https://docs.google.com/spreadsheets/d/other',
          rules_data: { columns: [], rules: [] }
        )
      end

      let(:other_automation) do
        other_user.automations.create!(
          template: other_template,
          status: 'scheduled',
          send_at: 1.hour.from_now,
          enabled: true,
          action_data: { to: 'other@example.com' }
        )
      end

      it 'redirects with error' do
        get :show, params: { id: other_automation.id }
        expect(response).to redirect_to(automations_path)
        expect(flash[:error]).to eq("Automation not found")
      end
    end
  end

  describe 'authentication' do
    before do
      allow(controller).to receive(:current_user).and_return(nil)
      allow(controller).to receive(:logged_in?).and_return(false)
    end

    it 'redirects to login when not authenticated' do
      get :index
      expect(response).to redirect_to(login_path)
    end
  end
end