require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:slack_service) { instance_double(SlackNotifierService) }

  before do
    allow(SlackNotifierService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:notify)
  end

  describe 'GET #new' do
    it 'renders login page' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    it 'logs in with valid credentials' do
      expect(slack_service).to receive(:notify).with(/logged in/, :success)
      post :create, params: { session: { email: user.email, password: 'password123' } }
      expect(cookies[:jwt]).to be_present
      expect(response).to redirect_to(templates_path)
    end

    it 'rejects invalid credentials' do
      expect(slack_service).to receive(:notify).with(/Failed login/, :warning)
      post :create, params: { session: { email: user.email, password: 'wrong' } }
      expect(cookies[:jwt]).to be_nil
      expect(response).to render_template(:new)
    end
  end

  describe 'DELETE #destroy' do
    before do
      token = controller.send(:encode_token, { user_id: user.id })
      cookies[:jwt] = token
    end

    it 'logs out user' do
      expect(slack_service).to receive(:notify).with(/logged out/)
      delete :destroy
      expect(cookies[:jwt]).to be_nil
      expect(response).to redirect_to(root_path)
    end
  end
end
