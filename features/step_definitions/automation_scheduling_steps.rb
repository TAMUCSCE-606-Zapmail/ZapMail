When('I send a schedule request for that template') do
    template = Template.find_by(name: 'Test1234')

    template.update!(
    rules_data: {
        'rules' => [
        {
            'conditions' => [
            { 'column' => 'Email', 'operator' => 'contains', 'value' => 'alice@company.com' }
            ],
            'action' => {
            'toColumn' => 'Email',
            'subject' => 'Hello {Name}',
            'body' => 'Test email',
            'oneTimeSendAt' => '2025-12-15T14:30'
            }
        }
        ]
    }.to_json
    )

    # Provide a mock spreadsheet that matches the rules
    data = [
    { 'Email' => 'alice@company.com', 'Name' => 'Alice' },
    { 'Email' => 'bob@company.com', 'Name' => 'Bob' }
    ]

    allow_any_instance_of(TemplatesController)
    .to receive(:fetch_spreadsheet_data)
    .and_return([
        { 'Email' => 'alice@company.com', 'Name' => 'Alice' }
    ])

    page.driver.submit :post, schedule_template_path(template), {
        rules_data: template.rules_data,
        spreadsheet_url: template.spreadsheet_url
    }
end

Then('I should receive a success response with scheduled_count greater than 0') do
    json = JSON.parse(page.body)
    expect(json['success']).to be true
    expect(json['scheduled_count']).to be > 0
end

Then('the template should have corresponding automation records created') do
    template = Template.find_by(name: @template.name)
    expect(template.automations.count).to be > 0

    first_automation = template.automations.first

    # Find the user by email
    expected_user = User.find_by(email: 'test@example.com')
    expect(first_automation.user).to eq(expected_user)

    expect(first_automation.status).to eq('scheduled')
    expect(first_automation.action_data).to include(
    'to' => kind_of(String),
    'subject' => kind_of(String),
    'body' => kind_of(String)
    )
end

When('I send a schedule request for that template with broken spreadsheet') do
    template = Template.find_by(name: @template.name)

    # Force a CSV parse error
    page.driver.submit :post, "/templates/#{template.id}/schedule", {
    rules_data: template.rules_data.to_json,
    spreadsheet_url: "https://invalid-url.example.com/broken.csv"
    }

    @json_response = JSON.parse(page.driver.response.body)
end

Then('I should receive a failure response with an error message') do
    expect(@json_response).not_to be_nil
    expect(@json_response['success']).to eq(false)
    expect(@json_response['error']).to be_a(String)
    expect(@json_response['error']).not_to be_empty
end
