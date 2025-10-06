require 'rails_helper'

RSpec.describe TemplatesController, type: :controller do
  let(:user) { User.create!(name: 'Test', email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:template) { user.templates.create!(name: 'Template', spreadsheet_url: 'https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit', rules_data: { columns: [ 'email' ], rules: [] }) }
  let(:valid_attributes) { { name: 'New', spreadsheet_url: 'http://example.com' } }
  let(:slack_service) { instance_double(SlackNotifierService) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(SlackNotifierService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:notify)
  end

  describe 'GET #index' do
    it 'lists templates' do
      get :index
      expect(assigns(:templates)).to include(template)
      expect(response).to be_successful
    end
  end

  describe 'GET #new' do
    it 'renders new form' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    it 'creates template' do
      expect(slack_service).to receive(:notify).with(/created a new template/)
      expect { post :create, params: { template: valid_attributes } }.to change(Template, :count).by(1)
      expect(response).to redirect_to(edit_template_path(Template.last))
    end

    it 'rejects invalid' do
      post :create, params: { template: { name: '' } }
      expect(response).to render_template(:new)
    end
  end

  describe 'GET #edit' do
    it 'renders edit form' do
      get :edit, params: { id: template.id }
      expect(response).to be_successful
    end
  end

  describe 'PATCH #update' do
    it 'updates template' do
      expect(slack_service).to receive(:notify).with(/updated the template/)
      patch :update, params: { id: template.id, template: { name: 'Updated' } }
      template.reload
      expect(template.name).to eq('Updated')
    end

    it 'rejects invalid' do
      patch :update, params: { id: template.id, template: { name: '' } }
      expect(response).to render_template(:edit)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes template' do
      expect(slack_service).to receive(:notify).with(/deleted/, :warning)
      expect { delete :destroy, params: { id: template.id } }.to change(Template, :count).by(-1)
    end
  end

  describe 'POST #duplicate' do
    it 'duplicates template' do
      expect(slack_service).to receive(:notify).with(/duplicated/)
      expect { post :duplicate, params: { id: template.id } }.to change(Template, :count).by(1)
      expect(Template.last.name).to eq("#{template.name} (Copy)")
    end
  end

  describe 'POST #verify_spreadsheet' do
    let(:data) { [ { 'email' => 'test@test.com', 'age' => '25' } ] }

    before { allow(controller).to receive(:fetch_spreadsheet_data).and_return(data) }

    it 'verifies spreadsheet' do
      post :verify_spreadsheet, params: { spreadsheet_url: 'http://test.com' }, format: :json
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['emailColumns']).to include('email')
    end

    it 'rejects without email column' do
      allow(controller).to receive(:fetch_spreadsheet_data).and_return([ { 'name' => 'Test' } ])
      post :verify_spreadsheet, params: { spreadsheet_url: 'http://test.com' }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'handles errors' do
      expect(slack_service).to receive(:notify).with(/failed/, :error)
      allow(controller).to receive(:fetch_spreadsheet_data).and_raise(StandardError, 'Error')
      post :verify_spreadsheet, params: { spreadsheet_url: 'http://bad.com' }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST #preview' do
    let(:data) { [ { 'email' => 'test@test.com', 'age' => '25' } ] }
    let(:rules) { { 'rules' => [ { 'conditions' => [ { 'column' => 'age', 'operator' => '>', 'value' => '18' } ], 'action' => { 'subject' => 'Hi', 'body' => 'Body', 'toColumn' => 'email' } } ] }.to_json }

    before { allow(controller).to receive(:fetch_spreadsheet_data).and_return(data) }

    it 'previews rules' do
      post :preview, params: { id: template.id, rules_data: rules, spreadsheet_url: 'http://test.com' }, format: :turbo_stream
      expect(response).to be_successful
    end

    it 'handles errors' do
      expect(slack_service).to receive(:notify).with(/failed/, :error)
      post :preview, params: { id: template.id, rules_data: '{bad', spreadsheet_url: 'http://test.com' }, format: :turbo_stream
      expect(response).to be_successful
    end
  end

  describe 'POST #schedule' do
    let(:data) { [ { 'email' => 'test@test.com', 'age' => '25' } ] }
    let(:rules) { { 'rules' => [ { 'conditions' => [ { 'column' => 'age', 'operator' => '>', 'value' => '18' } ], 'action' => { 'subject' => 'Hi', 'body' => 'Body', 'toColumn' => 'email', 'oneTimeSendAt' => 1.hour.from_now.iso8601 } } ] }.to_json }

    before { allow(controller).to receive(:fetch_spreadsheet_data).and_return(data) }

    it 'schedules automations' do
      expect(slack_service).to receive(:notify).with(/scheduled/, :success)
      expect { post :schedule, params: { id: template.id, rules_data: rules, spreadsheet_url: 'http://test.com' }, format: :json }.to change(Automation, :count).by(1)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    it 'handles errors' do
      expect(slack_service).to receive(:notify).with(/Failed to schedule/, :error)
      post :schedule, params: { id: template.id, rules_data: '{bad', spreadsheet_url: 'http://test.com' }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'private methods' do
    it 'converts Google Sheets URL' do
      url = 'https://docs.google.com/spreadsheets/d/123/edit?gid=0#gid=0'
      expect(controller.send(:convert_to_csv_export_url, url)).to eq('https://docs.google.com/spreadsheets/d/123/export?format=csv&gid=0')
    end

    it 'parses valid JSON rules_data' do
      params = ActionController::Parameters.new(template: { name: 'Test', spreadsheet_url: 'http://test.com', rules_data: { 'columns' => [ 'email' ] }.to_json })
      allow(controller).to receive(:params).and_return(params)
      result = controller.send(:processed_template_params)
      expect(result[:rules_data]).to be_a(Hash)
    end
  end

  describe 'RuleProcessorService' do
    let(:rules) { [ { 'conditions' => [ { 'column' => 'age', 'operator' => '>', 'value' => '18' } ], 'action' => { 'subject' => 'Hi {name}', 'body' => 'Age: {age}' } } ] }
    let(:data) { [ { 'name' => 'John', 'age' => '25' }, { 'name' => 'Jane', 'age' => '16' } ] }
    let(:processor) { TemplatesController::RuleProcessorService.new(rules, data) }

    it 'filters matching rows' do
      results = processor.run
      expect(results.size).to eq(1)
      expect(results.first[:row]['name']).to eq('John')
    end

    it 'substitutes placeholders' do
      results = processor.run
      expect(results.first[:substituted_subject]).to eq('Hi John')
      expect(results.first[:substituted_body]).to eq('Age: 25')
    end
  end
end
