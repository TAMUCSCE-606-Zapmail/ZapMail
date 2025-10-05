require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:valid_attributes) do
    {
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123',
      date_of_birth: '2000-01-01',
      major: 'Computer Science',
      classification: 'Junior',
      uin: '123456789'
    }
  end

  let(:invalid_attributes) do
    {
      name: '',
      email: 'invalid_email',
      password: '123',
      password_confirmation: '456'
    }
  end

  describe 'GET #new' do
    it 'returns http success' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'assigns a new user' do
      get :new
      expect(assigns(:user)).to be_a_new(User)
    end

    it 'renders the new template' do
      get :new
      expect(response).to render_template(:new)
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'logs in the user automatically' do
        post :create, params: { user: valid_attributes }
        expect(cookies[:jwt]).to be_present
      end

      it 'redirects to templates page' do
        post :create, params: { user: valid_attributes }
        expect(response).to redirect_to(templates_path)
      end

      it 'sets success flash message' do
        post :create, params: { user: valid_attributes }
        expect(flash[:success]).to eq('Welcome to the ZapMail! Your account was created successfully.')
      end

      it 'sends Slack success notification' do
        slack_service = instance_double(SlackNotifierService)
        allow(SlackNotifierService).to receive(:new).and_return(slack_service)
        expect(slack_service).to receive(:notify).with(
          /🎉 New user signed up: `test@example\.com`/,
          :success
        )

        post :create, params: { user: valid_attributes }
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new user' do
        expect {
          post :create, params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end

      it 'renders the new template' do
        post :create, params: { user: invalid_attributes }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not log in the user' do
        post :create, params: { user: invalid_attributes }
        expect(cookies[:jwt]).to be_nil
      end
    end
  end

  describe 'GET #show' do
    let(:user) { User.create!(valid_attributes) }

    context 'when logged in' do
      before do
        token = controller.send(:encode_token, { user_id: user.id })
        cookies[:jwt] = token
      end

      it 'returns http success' do
        get :show
        expect(response).to have_http_status(:success)
      end

      it 'assigns the current user' do
        get :show
        expect(assigns(:user)).to eq(user)
      end

      it 'renders the show template' do
        get :show
        expect(response).to render_template(:show)
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        get :show
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'GET #edit' do
    let(:user) { User.create!(valid_attributes) }

    context 'when logged in' do
      before do
        token = controller.send(:encode_token, { user_id: user.id })
        cookies[:jwt] = token
      end

      it 'returns http success' do
        get :edit
        expect(response).to have_http_status(:success)
      end

      it 'assigns the current user' do
        get :edit
        expect(assigns(:user)).to eq(user)
      end

      it 'renders the edit template' do
        get :edit
        expect(response).to render_template(:edit)
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        get :edit
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'PATCH #update' do
    let(:user) { User.create!(valid_attributes) }
    let(:new_attributes) { { name: 'Updated Name', major: 'Mathematics' } }

    context 'when logged in' do
      before do
        token = controller.send(:encode_token, { user_id: user.id })
        cookies[:jwt] = token
      end

      context 'with valid parameters' do
        it 'updates the user' do
          patch :update, params: { user: new_attributes }
          user.reload
          expect(user.name).to eq('Updated Name')
          expect(user.major).to eq('Mathematics')
        end

        it 'redirects to profile page' do
          patch :update, params: { user: new_attributes }
          expect(response).to redirect_to(profile_path)
        end

        it 'sets success flash message' do
          patch :update, params: { user: new_attributes }
          expect(flash[:success]).to eq('Your profile has been updated successfully.')
        end

        it 'sends Slack info notification' do
          slack_service = instance_double(SlackNotifierService)
          allow(SlackNotifierService).to receive(:new).and_return(slack_service)
          expect(slack_service).to receive(:notify).with("User `#{user.email}` updated their profile.")

          patch :update, params: { user: new_attributes }
        end
      end

      context 'with invalid parameters' do
        it 'does not update the user' do
          patch :update, params: { user: { email: 'invalid' } }
          user.reload
          expect(user.email).not_to eq('invalid')
        end

        it 'renders the edit template' do
          patch :update, params: { user: { email: 'invalid' } }
          expect(response).to render_template(:edit)
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'sends Slack warning notification' do
          slack_service = instance_double(SlackNotifierService)
          allow(SlackNotifierService).to receive(:new).and_return(slack_service)
          expect(slack_service).to receive(:notify).with(
            /User `#{user.email}` failed to update their profile/,
            :warning
          )

          patch :update, params: { user: { email: 'invalid' } }
        end
      end

      context 'updating password' do
        it 'allows password update' do
          patch :update, params: { 
            user: { 
              password: 'newpassword123', 
              password_confirmation: 'newpassword123' 
            } 
          }
          user.reload
          expect(user.authenticate('newpassword123')).to be_truthy
        end

        it 'ignores blank password fields' do
          old_password_digest = user.password_digest
          patch :update, params: { user: { password: '', password_confirmation: '' } }
          user.reload
          expect(user.password_digest).to eq(old_password_digest)
        end
      end
    end

    context 'when not logged in' do
      it 'redirects to login' do
        patch :update, params: { user: new_attributes }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end