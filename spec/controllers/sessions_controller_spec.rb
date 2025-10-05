require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) do
    User.create!(
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
  end

  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    context 'with valid credentials' do
      it 'logs in the user' do
        post :create, params: { session: { email: user.email, password: 'password123' } }
        expect(session[:user_id]).to be_nil # Using JWT cookies instead
        expect(cookies[:jwt]).to be_present
      end

      it 'redirects to templates page' do
        post :create, params: { session: { email: user.email, password: 'password123' } }
        expect(response).to redirect_to(templates_path)
      end

      it 'sets success flash message' do
        post :create, params: { session: { email: user.email, password: 'password123' } }
        expect(flash[:success]).to eq('You have successfully logged in.')
      end

      it 'sends Slack notification' do
        slack_service = instance_double(SlackNotifierService)
        allow(SlackNotifierService).to receive(:new).and_return(slack_service)
        expect(slack_service).to receive(:notify).with("User logged in: `#{user.email}`", :success)

        post :create, params: { session: { email: user.email, password: 'password123' } }
      end
    end

    context 'with invalid credentials' do
      it 'does not log in the user' do
        post :create, params: { session: { email: user.email, password: 'wrongpassword' } }
        expect(cookies[:jwt]).to be_nil
      end

      it 'renders the new template with error' do
        post :create, params: { session: { email: user.email, password: 'wrongpassword' } }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'sets error flash message' do
        post :create, params: { session: { email: user.email, password: 'wrongpassword' } }
        expect(flash[:error]).to eq('Invalid email or password.')
      end

      it 'sends Slack warning notification' do
        slack_service = instance_double(SlackNotifierService)
        allow(SlackNotifierService).to receive(:new).and_return(slack_service)
        expect(slack_service).to receive(:notify).with(
          "Failed login attempt for email: `#{user.email.downcase}`",
          :warning
        )

        post :create, params: { session: { email: user.email, password: 'wrongpassword' } }
      end
    end

    context 'with non-existent email' do
      it 'does not log in the user' do
        post :create, params: { session: { email: 'nonexistent@example.com', password: 'password123' } }
        expect(cookies[:jwt]).to be_nil
      end

      it 'renders the new template with error' do
        post :create, params: { session: { email: 'nonexistent@example.com', password: 'password123' } }
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      # Simulate logged-in user
      token = controller.send(:encode_token, { user_id: user.id })
      cookies[:jwt] = token
    end

    it 'logs out the user' do
      delete :destroy
      expect(cookies[:jwt]).to be_nil
    end

    it 'redirects to root path' do
      delete :destroy
      expect(response).to redirect_to(root_path)
    end

    it 'sets success flash message' do
      delete :destroy
      expect(flash[:success]).to eq('You have successfully logged out.')
    end

    it 'sends Slack info notification' do
      slack_service = instance_double(SlackNotifierService)
      allow(SlackNotifierService).to receive(:new).and_return(slack_service)
      expect(slack_service).to receive(:notify).with("User logged out: `#{user.email}`")

      delete :destroy
    end

    context 'when not logged in' do
      before do
        cookies.delete(:jwt)
      end

      it 'still succeeds' do
        delete :destroy
        expect(response).to redirect_to(root_path)
      end

      it 'does not send Slack notification' do
        slack_service = instance_double(SlackNotifierService)
        allow(SlackNotifierService).to receive(:new).and_return(slack_service)
        expect(slack_service).not_to receive(:notify)

        delete :destroy
      end
    end
  end
end