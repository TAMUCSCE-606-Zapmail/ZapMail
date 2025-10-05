require 'rails_helper'

RSpec.describe TemplatesController, type: :controller do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123') }
  let(:other_user) { User.create!(name: 'Other User', email: 'other@example.com', password: 'password123') }

  let!(:template) { user.templates.create!(name: 'My Template', spreadsheet_url: 'http://example.com/sheet') }
  let!(:other_template) { other_user.templates.create!(name: 'Others Template', spreadsheet_url: 'http://example.com/other') }

  let(:valid_attributes) { { name: 'New Template', spreadsheet_url: 'http://example.com/new' } }
  let(:invalid_attributes) { { name: '' } }

  # Mock authentication for all tests
  before do
    # Stub the authorize before_action to simulate a logged-in user
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'assigns only the current user\'s templates' do
      get :index
      expect(assigns(:templates)).to include(template)
      expect(assigns(:templates)).not_to include(other_template)
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new
      expect(response).to be_successful
    end

    it 'assigns a new template' do
      get :new
      expect(assigns(:template)).to be_a_new(Template)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Template' do
        expect {
          post :create, params: { template: valid_attributes }
        }.to change(Template, :count).by(1)
      end

      it 'redirects to the edit page for the new template' do
        post :create, params: { template: valid_attributes }
        expect(response).to redirect_to(edit_template_path(Template.last))
      end

      it 'sends a Slack notification' do
        expect_any_instance_of(SlackNotifierService).to receive(:notify).with(/created a new template/)
        post :create, params: { template: valid_attributes }
      end
    end

    context 'with invalid params' do
      it 'does not create a new Template' do
        expect {
          post :create, params: { template: invalid_attributes }
        }.not_to change(Template, :count)
      end

      it 'renders the new template with an error status' do
        post :create, params: { template: invalid_attributes }
        expect(response).to render_template(:new)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns a success response' do
      get :edit, params: { id: template.to_param }
      expect(response).to be_successful
    end

it 'assigns the correct template' do
      get :edit, params: { id: template.to_param }
      expect(assigns(:template)).to eq(template)
    end

    it 'does not allow editing of another user\'s template' do
      expect {
        get :edit, params: { id: other_template.to_param }
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'PATCH #update' do
    context 'with valid params' do
      let(:new_attributes) { { name: 'Updated Name' } }

      it 'updates the requested template' do
        patch :update, params: { id: template.to_param, template: new_attributes }
        template.reload
        expect(template.name).to eq('Updated Name')
      end

      it 'redirects to the edit template page' do
        patch :update, params: { id: template.to_param, template: new_attributes }
        expect(response).to redirect_to(edit_template_path(template))
      end

      it 'sends a Slack notification' do
        expect_any_instance_of(SlackNotifierService).to receive(:notify).with(/updated the template/)
        patch :update, params: { id: template.to_param, template: new_attributes }
      end
    end

    context 'with invalid params' do
      it 'does not update the template' do
        patch :update, params: { id: template.to_param, template: invalid_attributes }
        template.reload
        expect(template.name).not_to eq('')
      end

      it 'renders the edit template with an error status' do
        patch :update, params: { id: template.to_param, template: invalid_attributes }
        expect(response).to render_template(:edit)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested template' do
      expect {
        delete :destroy, params: { id: template.to_param }
      }.to change(Template, :count).by(-1)
    end

    it 'redirects to the templates list' do
      delete :destroy, params: { id: template.to_param }
      expect(response).to redirect_to(templates_url)
    end

    it 'sends a Slack notification' do
      expect_any_instance_of(SlackNotifierService).to receive(:notify).with(/deleted the template/, :warning)
      delete :destroy, params: { id: template.to_param }
    end
  end

  describe 'POST #duplicate' do
    it 'creates a copy of the template' do
      expect {
        post :duplicate, params: { id: template.to_param }
      }.to change(Template, :count).by(1)
    end

    it 'names the new template with a (Copy) suffix' do
      post :duplicate, params: { id: template.to_param }
      expect(Template.last.name).to eq("#{template.name} (Copy)")
    end

    it 'redirects to the templates index' do
      post :duplicate, params: { id: template.to_param }
      expect(response).to redirect_to(templates_path)
    end

    it 'sends a Slack notification' do
      expect_any_instance_of(SlackNotifierService).to receive(:notify).with(/duplicated the template/)
      post :duplicate, params: { id: template.to_param }
    end
  end

  describe 'Authentication' do
    before do
      # Un-stub the authorization mocks for this context
      allow(controller).to receive(:authorize).and_call_original
      allow(controller).to receive(:current_user).and_return(nil)
    end

    it 'redirects GET #index to login' do
      get :index
      expect(response).to redirect_to(login_path)
    end

    it 'redirects POST #create to login' do
      post :create, params: { template: valid_attributes }
      expect(response).to redirect_to(login_path)
    end

    it 'redirects GET #edit to login' do
      get :edit, params: { id: template.to_param }
      expect(response).to redirect_to(login_path)
    end
  end
end