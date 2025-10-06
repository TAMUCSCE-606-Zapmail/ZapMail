require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:valid_attributes) { { name: 'Test User', email: 'test@example.com', password: 'password123', password_confirmation: 'password123', date_of_birth: '2000-01-01', major: 'CS', classification: 'Junior', uin: '123456789' } }
  let(:invalid_attributes) { { name: '', email: 'invalid' } }
  let(:user) { User.create!(valid_attributes) }
  let(:slack_service) { instance_double(SlackNotifierService) }

  before do
    allow(SlackNotifierService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:notify)
  end

  describe 'GET #new' do
    it 'renders signup page' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    it 'creates user with valid params' do
      expect(slack_service).to receive(:notify).with(/signed up/, :success)
      expect { post :create, params: { user: valid_attributes } }.to change(User, :count).by(1)
      expect(cookies[:jwt]).to be_present
      expect(response).to redirect_to(templates_path)
    end

    it 'rejects invalid params' do
      expect { post :create, params: { user: invalid_attributes } }.not_to change(User, :count)
      expect(response).to render_template(:new)
    end
  end

  describe 'GET #show' do
    before { allow(controller).to receive(:current_user).and_return(user) }

    it 'shows profile when logged in' do
      get :show
      expect(response).to be_successful
    end

    it 'redirects when not logged in' do
      allow(controller).to receive(:current_user).and_return(nil)
      get :show
      expect(response).to redirect_to(login_path)
    end
  end

  describe 'GET #edit' do
    before { allow(controller).to receive(:current_user).and_return(user) }

    it 'renders edit page' do
      get :edit
      expect(response).to be_successful
    end
  end

  describe 'PATCH #update' do
    before { allow(controller).to receive(:current_user).and_return(user) }

    it 'updates with valid params' do
      expect(slack_service).to receive(:notify).with(/updated their profile/)
      patch :update, params: { user: { name: 'Updated' } }
      user.reload
      expect(user.name).to eq('Updated')
      expect(response).to redirect_to(profile_path)
    end

    it 'rejects invalid params' do
      expect(slack_service).to receive(:notify).with(/failed to update/, :warning)
      patch :update, params: { user: { email: 'invalid' } }
      expect(response).to render_template(:edit)
    end

    it 'ignores blank passwords' do
      old_digest = user.password_digest
      patch :update, params: { user: { password: '', password_confirmation: '' } }
      user.reload
      expect(user.password_digest).to eq(old_digest)
    end
  end
end
