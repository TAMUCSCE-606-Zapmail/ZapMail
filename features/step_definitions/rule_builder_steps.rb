Given("I have the following rules:") do |table|
  # Convert Gherkin table to JSON-like array
  @rules = table.hashes.map do |row|
    {
      'conditions' => JSON.parse(row['conditions']),
      'action' => JSON.parse(row['action'])
    }
  end
end

Given("I have the following data:") do |table|
  @data = table.hashes
end

When("I process the rules") do
  service = TemplatesController::RuleProcessorService.new(@rules, @data)
  @results = service.run
end

Then("I should see {int} result") do |count|
  expect(@results.size).to eq(count)
end

Then("the first result's substituted_subject should be {string}") do |subject|
  expect(@results.first[:substituted_subject]).to eq(subject)
end

Then("the first result's substituted_body should be {string}") do |body|
  expect(@results.first[:substituted_body]).to eq(body)
end

Given("a set of rules with various operators") do
  @rules = [
    {
      "conditions" => [{ "column" => "a", "operator" => "==", "value" => "5" }],
      "action" => { "subject" => "Equal", "body" => "A equals 5" }
    },
    {
      "conditions" => [{ "column" => "b", "operator" => "!=", "value" => "10" }],
      "action" => { "subject" => "NotEqual", "body" => "B not 10" }
    },
    {
      "conditions" => [{ "column" => "c", "operator" => ">", "value" => "3" }],
      "action" => { "subject" => "Greater", "body" => "C > 3" }
    },
    {
      "conditions" => [{ "column" => "d", "operator" => "<", "value" => "20" }],
      "action" => { "subject" => "Less", "body" => "D < 20" }
    },
    {
      "conditions" => [{ "column" => "e", "operator" => "contains", "value" => "hello" }],
      "action" => { "subject" => "Contains", "body" => "E contains hello" }
    },
    {
      "conditions" => [{ "column" => "f", "operator" => "not_contains", "value" => "bye" }],
      "action" => { "subject" => "NotContains", "body" => "F does not contain bye" }
    },
    {
      "conditions" => [{ "column" => "g", "operator" => "invalid", "value" => "x" }],
      "action" => { "subject" => "Invalid", "body" => "Should not match" }
    }
  ]
end

Given("corresponding data rows") do
  @data = [
    { "a" => "5" },                        # ==
    { "b" => "8" },                        # !=
    { "c" => "10" },                       # >
    { "d" => "15" },                       # <
    { "e" => "Hello world" },              # contains
    { "f" => "Good morning" },             # not_contains
    { "g" => "y" }                         # invalid operator
  ]
end

Then("each rule should be evaluated correctly") do
  subjects = @results.map { |r| r[:action]["subject"] }
  expect(subjects).to include("Equal", "NotEqual", "Greater", "Less", "Contains", "NotContains")
  expect(subjects).not_to include("Invalid")
end

When("I visit the new template page") do
  visit new_template_path
end

When("I enter {string} as my template name") do |template_name|
    fill_in "template_name", with: template_name
end

When("I enter a valid Google Sheet URL") do
    fill_in "template_spreadsheet_url", with: "https://docs.google.com/spreadsheets/d/1CLQDMI4Fs44c85iQGuyyz8TD48qDZMPUgQiEzyjKbDg/edit?gid=0#gid=0"
end

When("I click the Verify & Load button") do
    click_button "Verify & Load"
end

When("I select column {string} as my condition rule column") do |value|
  select_box = find('select[data-rule-condition="column"]', visible: true, wait: 5)
  
  option = select_box.find("option", text: value, wait: 5)
  option.select_option
end

When("I select operator {string} as my condition rule operator") do |value|
    select_box = find('select[data-rule-condition="operator"]', visible: true, wait: 5)
  
    option = select_box.find("option", text: value, wait: 5)
    option.select_option
end

When("I fill in {string} as my condition rule value") do |value|
    input = find('input[data-rule-condition="value"]', visible: true, wait: 5)

    # Clear any pre-filled content and fill in the new value
    input.set('')   # optional: clear existing content
    input.set(value)
end

When("I select column {string} as my Email To column") do |value|
    select_box = find('select[data-rule-action="toColumn"]', visible: true, wait: 5)
  
    option = select_box.find("option", text: value, wait: 5)
    option.select_option
end

When("I fill in {string} as my email subject") do |value|
    input = find('input[data-rule-action="subject"]', visible: true, wait: 5)

    # Clear any pre-filled content and fill in the new value
    input.send_keys(:backspace) # clear existing value
    input.send_keys(value)
    input.send_keys(:tab)
end

When("I fill in {string} as my email body") do |value|
    input = find('textarea[data-rule-action="body"]', visible: true, wait: 5)

    # Clear any pre-filled content and fill in the new value
    input.send_keys(:backspace) # clear existing value
    input.send_keys(value)
    input.send_keys(:tab)
end

When("I set the schedule date-time to {string}") do |datetime|
    # Find the datetime input
    input = find('input[type="datetime-local"]', visible: true, wait: 5)

    # Clear any existing value
    input.set('')

    # Fill in the new value
    # Format must be: "YYYY-MM-DDTHH:MM"
    # Example: "2025-10-05T14:30"
    input.set(datetime)
    input.send_keys(:tab)
end

When("I save my template") do
    # Wait up to 5 seconds for the button to appear and be enabled
    button = find('input[data-form-verification-target="saveButton"]', visible: true, wait: 5)

    # Click the button
    button.click
end

When("I close the template") do
    # Wait for the button to appear and be visible
    link = find('a[title="Back to Templates"]', visible: true, wait: 5)

    # Click the button
    link.click
end

Given("I have an existing template named {string} with rules and a valid spreadsheet url") do |name|
    user = User.find_by(email: "test@example.com") || User.create!(email: "test@example.com", password: "password123")

    rules_json = {
    "rules": [
        {
        "action": {
            "body": "You are so cool!",
            "type": "sendEmail",
            "subject": "Hi {emails} ",
            "toColumn": "emails",
            "isRepeating": true,
            "oneTimeSendAt": nil,
            "repeatDeadline": "2025-11-29",
            "repeatFrequency": "weekly"
        },
        "conditions": [
            { "value": "5", "column": "response_rate", "operator": "==" }
        ]
        }
    ],
    "columns": [
        { "name": "emails", "type": "number" },
        { "name": "response_rate", "type": "string" },
        { "name": "finish_rate", "type": "string" },
        { "name": "test", "type": "string" }
    ]
    }

    @template = user.templates.create!(
    name: name,
    spreadsheet_url: "https://docs.google.com/spreadsheets/d/1CLQDMI4Fs44c85iQGuyyz8TD48qDZMPUgQiEzyjKbDg/edit?gid=0#gid=0",
    rules_data: rules_json
    )
end

When("I visit the edit page for my {string} template") do |template_name|
    visit '/templates'

    summary = find('summary', text: template_name)

    # Within this summary, click the Edit link
    within(summary) do
        click_link('Edit')
    end
end

When("I change the template name to {string}") do |new_template_name|
    fill_in "template_name", with: new_template_name
end

# In a step definition
Given("I force the template save to fail") do
  # Find the Template instance your controller will use
  allow_any_instance_of(Template).to receive(:save).and_return(false)
end

Given("I force the template update to fail") do
  allow_any_instance_of(Template).to receive(:update).and_return(false)
end

When('I submit the template form directly') do
    page.driver.submit :post, '/templates', {
    template: {
        name: '',                     # Blank to trigger validation failure
        spreadsheet_url: 'invalid-url',
        rules_data: '[]'              # Optional if required
    }
    }
end

When("I submit the template update directly") do
  template = Template.find_by(name: "Test1234") # or however you locate the template

  page.driver.submit :patch, "/templates/#{template.id}", {
    template: {
      name: "",                     # Blank to trigger validation failure
      spreadsheet_url: template.spreadsheet_url,
      rules_data: template.rules_data
    }
  }
end

Then("nothing happens") do
end

When("I delete the template named {string}") do |template_name|
    # Find the summary element that contains the template name
    summary = find('summary', text: template_name)

    # Within that summary, find the delete form (method=post with hidden _method=delete)
    delete_form = summary.find(:xpath, './/form[input[@name="_method" and @value="delete"]]')

    # Submit the form by clicking the submit button
    delete_form.find('button[type="submit"]').click
end

Then("I should not see {string}") do |string|
    expect(page).to have_no_text(string)
end

When('I duplicate the template named {string}') do |template_name|
  # Find the summary element containing the template name
  summary = find('summary', text: template_name)

  # Find the duplicate form inside that summary (action ends with /duplicate)
  duplicate_form = summary.find(:xpath, './/form[contains(@action, "/duplicate")]')

  # Submit the duplicate form
  duplicate_form.find('button[type="submit"]').click
end

When('I submit a duplicate request directly for template {string}') do |template_name|
  template = Template.find_by(name: template_name)
  page.driver.submit :post, "/templates/#{template.id}/duplicate", {}
end

Before('@duplicate_sad_path') do
  # Any instance of Template will fail to save
  allow_any_instance_of(Template).to receive(:save).and_return(false)
end

