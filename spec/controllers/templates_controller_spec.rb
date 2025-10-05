require 'rails_helper'

RSpec.describe TemplatesController, type: :controller do
  let(:user) { User.create!(name: 'Test User', email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:other_user) { User.create!(name: 'Other User', email: 'other@example.com', password: 'password123', password_confirmation: 'password123') }

  let!(:template) do
    user.templates.create!(
      name: 'My Template',
      spreadsheet_url: 'https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit',
      rules_data: {
        'columns' => ['name', 'email', 'age'],
        'rules' => [
          {
            'conditions' => [{ 'column' => 'age', 'operator' => '>', 'value' => '18' }],
            'action' => {
              'subject' => 'Hi {name}',
              'body' => 'You are {age}',
              'toColumn' => 'email',
              'oneTimeSendAt' => 2.hours.from_now.iso8601
            }
          }
        ]
      }
    )
  end

  let!(:other_template) { other_user.templates.create!(name: 'Others Template', spreadsheet_url: 'http://example.com/other') }

  let(:valid_attributes) { { name: 'New Template', spreadsheet_url: 'http://example.com/new' } }
  let(:invalid_attributes) { { name: '' } }

  let(:slack_service) { instance_double(SlackNotifierService) }

  before do
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
    allow(SlackNotifierService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:notify)
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
        expect(slack_service).to receive(:notify).with(/created a new template/)
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
        expect(slack_service).to receive(:notify).with(/updated the template/)
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
      template_to_delete = user.templates.create!(name: 'To Delete', spreadsheet_url: 'http://example.com')
      expect {
        delete :destroy, params: { id: template_to_delete.to_param }
      }.to change(Template, :count).by(-1)
    end

    it 'redirects to the templates list' do
      delete :destroy, params: { id: template.to_param }
      expect(response).to redirect_to(templates_url)
    end

    it 'sends a Slack notification' do
      expect(slack_service).to receive(:notify).with(/deleted the template/, :warning)
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
      expect(slack_service).to receive(:notify).with(/duplicated the template/)
      post :duplicate, params: { id: template.to_param }
    end

    context 'when duplication fails' do
      before do
        allow_any_instance_of(Template).to receive(:save).and_return(false)
      end

      it 'redirects with alert' do
        post :duplicate, params: { id: template.to_param }
        expect(response).to redirect_to(templates_path)
        expect(flash[:alert]).to eq("Could not duplicate the template.")
      end
    end
  end

  describe 'POST #verify_spreadsheet' do
    let(:sample_data) do
      [
        { 'name' => 'John Doe', 'email' => 'john@example.com', 'age' => '25' },
        { 'name' => 'Jane Smith', 'email' => 'jane@example.com', 'age' => '30' }
      ]
    end

    before do
      allow(controller).to receive(:fetch_spreadsheet_data).and_return(sample_data)
    end

    context 'with valid spreadsheet URL' do
      it 'returns success with column metadata' do
        post :verify_spreadsheet, params: { spreadsheet_url: template.spreadsheet_url }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['columns']).to be_an(Array)
        expect(json['columns'].size).to eq(3)
      end

      it 'identifies email columns' do
        post :verify_spreadsheet, params: { spreadsheet_url: template.spreadsheet_url }, format: :json

        json = JSON.parse(response.body)
        expect(json['emailColumns']).to include('email')
      end

      it 'identifies numeric columns' do
        post :verify_spreadsheet, params: { spreadsheet_url: template.spreadsheet_url }, format: :json

        json = JSON.parse(response.body)
        age_column = json['columns'].find { |c| c['name'] == 'age' }
        expect(age_column['type']).to eq('number')
      end

      it 'identifies string columns' do
        post :verify_spreadsheet, params: { spreadsheet_url: template.spreadsheet_url }, format: :json

        json = JSON.parse(response.body)
        name_column = json['columns'].find { |c| c['name'] == 'name' }
        expect(name_column['type']).to eq('string')
      end
    end

    context 'when no email column exists' do
      let(:data_without_email) do
        [
          { 'name' => 'John', 'age' => '25' },
          { 'name' => 'Jane', 'age' => '30' }
        ]
      end

      before do
        allow(controller).to receive(:fetch_spreadsheet_data).and_return(data_without_email)
      end

      it 'returns error response' do
        post :verify_spreadsheet, params: { spreadsheet_url: 'http://test.com' }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to match(/No 'email' column found/)
      end
    end

    context 'when spreadsheet fetch fails' do
      before do
        allow(controller).to receive(:fetch_spreadsheet_data).and_raise(StandardError, 'Network error')
      end

      it 'returns error response' do
        post :verify_spreadsheet, params: { spreadsheet_url: 'http://invalid.com' }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to include('Network error')
      end

      it 'sends Slack error notification' do
        expect(slack_service).to receive(:notify).with(/Spreadsheet verification failed/, :error)
        post :verify_spreadsheet, params: { spreadsheet_url: 'http://invalid.com' }, format: :json
      end
    end
  end

  describe 'POST #preview' do
    let(:sample_data) do
      [
        { 'name' => 'Adult User', 'email' => 'adult@example.com', 'age' => '25' },
        { 'name' => 'Minor User', 'email' => 'minor@example.com', 'age' => '16' },
        { 'name' => 'Senior User', 'email' => 'senior@example.com', 'age' => '65' }
      ]
    end

    let(:rules_json) do
      {
        'rules' => [
          {
            'conditions' => [{ 'column' => 'age', 'operator' => '>', 'value' => '18' }],
            'action' => {
              'subject' => 'Hello {name}',
              'body' => 'Your age is {age}',
              'toColumn' => 'email'
            }
          }
        ]
      }.to_json
    end

    before do
      allow(controller).to receive(:fetch_spreadsheet_data).and_return(sample_data)
    end

    context 'with valid parameters' do
      it 'processes rules and renders turbo stream' do
        post :preview,
             params: {
               id: template.id,
               rules_data: rules_json,
               spreadsheet_url: template.spreadsheet_url
             },
             format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it 'filters rows based on rules' do
        post :preview,
             params: {
               id: template.id,
               rules_data: rules_json,
               spreadsheet_url: template.spreadsheet_url
             },
             format: :turbo_stream

        # The RuleProcessorService should filter out the minor (age 16)
        expect(assigns(:paginated_results).size).to eq(2)
      end

      it 'paginates results' do
        large_data = Array.new(10) do |i|
          { 'name' => "User#{i}", 'email' => "user#{i}@example.com", 'age' => '25' }
        end
        allow(controller).to receive(:fetch_spreadsheet_data).and_return(large_data)

        post :preview,
             params: {
               id: template.id,
               rules_data: rules_json,
               spreadsheet_url: template.spreadsheet_url,
               page: 1
             },
             format: :turbo_stream

        expect(assigns(:paginated_results).size).to be <= 5
      end
    end

    context 'when JSON parsing fails' do
      it 'renders error turbo stream' do
        post :preview,
             params: {
               id: template.id,
               rules_data: '{invalid json',
               spreadsheet_url: template.spreadsheet_url
             },
             format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(assigns(:error_message)).to be_present
      end

      it 'sends Slack error notification' do
        expect(slack_service).to receive(:notify).with(/Rule preview failed/, :error)

        post :preview,
             params: {
               id: template.id,
               rules_data: '{invalid',
               spreadsheet_url: template.spreadsheet_url
             },
             format: :turbo_stream
      end
    end

    context 'when spreadsheet fetch fails' do
      before do
        allow(controller).to receive(:fetch_spreadsheet_data).and_raise(StandardError, 'Connection timeout')
      end

      it 'renders error turbo stream' do
        post :preview,
             params: {
               id: template.id,
               rules_data: rules_json,
               spreadsheet_url: 'http://bad.url'
             },
             format: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(assigns(:error_message)).to eq('Connection timeout')
      end
    end
  end

  describe 'POST #schedule' do
    let(:sample_data) do
      [
        { 'name' => 'John Doe', 'email' => 'john@example.com', 'age' => '25' },
        { 'name' => 'Jane Smith', 'email' => 'jane@example.com', 'age' => '30' },
        { 'name' => 'Bob Minor', 'email' => 'bob@example.com', 'age' => '15' }
      ]
    end

    let(:schedule_time) { 2.hours.from_now }

    let(:rules_json) do
      {
        'rules' => [
          {
            'conditions' => [{ 'column' => 'age', 'operator' => '>', 'value' => '18' }],
            'action' => {
              'subject' => 'Welcome {name}',
              'body' => 'You are {age} years old',
              'toColumn' => 'email',
              'oneTimeSendAt' => schedule_time.iso8601
            }
          }
        ]
      }.to_json
    end

    before do
      allow(controller).to receive(:fetch_spreadsheet_data).and_return(sample_data)
    end

    context 'with valid parameters' do
      it 'creates automation records' do
        expect {
          post :schedule,
               params: {
                 id: template.id,
                 rules_data: rules_json,
                 spreadsheet_url: template.spreadsheet_url
               },
               format: :json
        }.to change(Automation, :count).by(2) # Only 2 adults
      end

      it 'sets correct automation attributes' do
        post :schedule,
             params: {
               id: template.id,
               rules_data: rules_json,
               spreadsheet_url: template.spreadsheet_url
             },
             format: :json

        automation = Automation.last
        expect(automation.status).to eq('scheduled')
        expect(automation.user).to eq(user)
        expect(automation.template).to eq(template)
        expect(automation.action_data['to']).to be_present
        expect(automation.action_data['subject']).to include('Welcome')
      end

      it 'returns success JSON with count' do
        post :schedule,
             params: {
               id: template.id,
               rules_data: rules_json,
               spreadsheet_url: template.spreadsheet_url
             },
             format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['scheduled_count']).to eq(2)
      end

      it 'sends Slack success notification' do
        expect(slack_service).to receive(:notify).with(/scheduled 2 emails/, :success)

        post :schedule,
             params: {
               id: template.id,
               rules_data: rules_json,
               spreadsheet_url: template.spreadsheet_url
             },
             format: :json
      end

      it 'substitutes placeholders in email content' do
        post :schedule,
             params: {
               id: template.id,
               rules_data: rules_json,
               spreadsheet_url: template.spreadsheet_url
             },
             format: :json

        automation = Automation.last
        expect(automation.action_data['subject']).to match(/Welcome (John Doe|Jane Smith)/)
        expect(automation.action_data['body']).to match(/You are (25|30) years old/)
      end
    end

    context 'when JSON parsing fails' do
      it 'returns error JSON' do
        post :schedule,
             params: {
               id: template.id,
               rules_data: '{bad json',
               spreadsheet_url: template.spreadsheet_url
             },
             format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to be_present
      end

      it 'sends Slack error notification' do
        expect(slack_service).to receive(:notify).with(/Failed to schedule/, :error)

        post :schedule,
             params: {
               id: template.id,
               rules_data: 'invalid',
               spreadsheet_url: template.spreadsheet_url
             },
             format: :json
      end
    end

    context 'when spreadsheet fetch fails' do
      before do
        allow(controller).to receive(:fetch_spreadsheet_data).and_raise(StandardError, 'API error')
      end

      it 'returns error JSON' do
        post :schedule,
             params: {
               id: template.id,
               rules_data: rules_json,
               spreadsheet_url: 'http://bad.url'
             },
             format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['error']).to eq('API error')
      end
    end

    context 'when no rows match rules' do
      let(:no_match_data) do
        [{ 'name' => 'Child', 'email' => 'child@example.com', 'age' => '10' }]
      end

      before do
        allow(controller).to receive(:fetch_spreadsheet_data).and_return(no_match_data)
      end

      it 'creates zero automations' do
        expect {
          post :schedule,
               params: {
                 id: template.id,
                 rules_data: rules_json,
                 spreadsheet_url: template.spreadsheet_url
               },
               format: :json
        }.not_to change(Automation, :count)
      end

      it 'returns success with zero count' do
        post :schedule,
             params: {
               id: template.id,
               rules_data: rules_json,
               spreadsheet_url: template.spreadsheet_url
             },
             format: :json

        json = JSON.parse(response.body)
        expect(json['scheduled_count']).to eq(0)
      end
    end
  end

  describe 'private methods' do
    describe '#convert_to_csv_export_url' do
      it 'converts Google Sheets URL to CSV export URL' do
        original_url = 'https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit?gid=0#gid=0'
        expected_url = 'https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/export?format=csv&gid=0'

        converted = controller.send(:convert_to_csv_export_url, original_url)
        expect(converted).to eq(expected_url)
      end

      it 'returns original URL if not a Google Sheets URL' do
        original_url = 'https://example.com/data.csv'
        converted = controller.send(:convert_to_csv_export_url, original_url)
        expect(converted).to eq(original_url)
      end
    end

    describe '#processed_template_params' do
      it 'parses valid JSON rules_data' do
        params = ActionController::Parameters.new(
          template: {
            name: 'Test',
            spreadsheet_url: 'http://test.com',
            rules_data: { 'columns' => ['email'], 'rules' => [] }.to_json
          }
        )
        allow(controller).to receive(:params).and_return(params)

        result = controller.send(:processed_template_params)
        expect(result[:rules_data]).to be_a(Hash)
        expect(result[:rules_data]['columns']).to eq(['email'])
      end

      it 'removes invalid JSON rules_data' do
        params = ActionController::Parameters.new(
          template: {
            name: 'Test',
            spreadsheet_url: 'http://test.com',
            rules_data: '{invalid json'
          }
        )
        allow(controller).to receive(:params).and_return(params)

        result = controller.send(:processed_template_params)
        expect(result).not_to have_key(:rules_data)
      end
    end
  end

  describe 'RuleProcessorService' do
    let(:rules) do
      [
        {
          'conditions' => [
            { 'column' => 'age', 'operator' => '>', 'value' => '18' },
            { 'column' => 'status', 'operator' => '==', 'value' => 'active' }
          ],
          'action' => {
            'subject' => 'Hello {name}',
            'body' => 'You are {age} years old'
          }
        }
      ]
    end

    let(:data) do
      [
        { 'name' => 'John', 'age' => '25', 'status' => 'active' },
        { 'name' => 'Jane', 'age' => '16', 'status' => 'active' },
        { 'name' => 'Bob', 'age' => '30', 'status' => 'inactive' }
      ]
    end

    let(:processor) { TemplatesController::RuleProcessorService.new(rules, data) }

    it 'filters rows matching all conditions' do
      results = processor.run
      expect(results.size).to eq(1)
      expect(results.first[:row]['name']).to eq('John')
    end

    it 'substitutes placeholders in subject and body' do
      results = processor.run
      expect(results.first[:substituted_subject]).to eq('Hello John')
      expect(results.first[:substituted_body]).to eq('You are 25 years old')
    end

    it 'handles numeric comparisons' do
      numeric_rules = [
        {
          'conditions' => [{ 'column' => 'age', 'operator' => '<', 'value' => '20' }],
          'action' => { 'subject' => 'Young', 'body' => 'Body' }
        }
      ]
      processor = TemplatesController::RuleProcessorService.new(numeric_rules, data)
      results = processor.run
      expect(results.size).to eq(1)
      expect(results.first[:row]['name']).to eq('Jane')
    end

    it 'handles contains operator' do
      contains_rules = [
        {
          'conditions' => [{ 'column' => 'name', 'operator' => 'contains', 'value' => 'Jo' }],
          'action' => { 'subject' => 'Match', 'body' => 'Body' }
        }
      ]
      processor = TemplatesController::RuleProcessorService.new(contains_rules, data)
      results = processor.run
      expect(results.size).to eq(1)
      expect(results.first[:row]['name']).to eq('John')
    end

    it 'handles not_contains operator' do
      not_contains_rules = [
        {
          'conditions' => [{ 'column' => 'status', 'operator' => 'not_contains', 'value' => 'inactive' }],
          'action' => { 'subject' => 'Active', 'body' => 'Body' }
        }
      ]
      processor = TemplatesController::RuleProcessorService.new(not_contains_rules, data)
      results = processor.run
      expect(results.size).to eq(2)
    end

    it 'returns empty array when no conditions match' do
      no_match_rules = [
        {
          'conditions' => [{ 'column' => 'age', 'operator' => '>', 'value' => '100' }],
          'action' => { 'subject' => 'Old', 'body' => 'Body' }
        }
      ]
      processor = TemplatesController::RuleProcessorService.new(no_match_rules, data)
      results = processor.run
      expect(results).to be_empty
    end

    it 'handles missing column gracefully' do
      bad_rules = [
        {
          'conditions' => [{ 'column' => 'nonexistent', 'operator' => '==', 'value' => 'test' }],
          'action' => { 'subject' => 'Test', 'body' => 'Body' }
        }
      ]
      processor = TemplatesController::RuleProcessorService.new(bad_rules, data)
      results = processor.run
      expect(results).to be_empty
    end
  end

  describe 'Authentication' do
    before do
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