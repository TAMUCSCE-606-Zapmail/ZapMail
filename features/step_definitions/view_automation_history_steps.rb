Given("I have the following automations:") do |table|
  user = User.find_by(email: "test@example.com")
  table.hashes.each do |row|
    template = Template.create!(name: row['template_name'], user: user, rules_data: [])
    Automation.create!(
      user: user,
      template: template,
      status: row['status'],
      send_at: row['send_at'],
      action_data: { to: "test@example.com", subject: "Hello", body: "World" } # dummy data
    )
  end
end

Given("I have an automation with template {string} and status {string}") do |template_name, status|
  user = User.find_by(email: "test@example.com")
  template = Template.create!(name: template_name, user: user, rules_data: [])
  Automation.create!(
    user: user,
    template: template,
    status: status,
    send_at: 1.hour.from_now,
    action_data: { to: "test@example.com", subject: "Hello", body: "World" } # dummy data
  )
end


When("I visit the automations page") do
  visit automations_path
end

When("I visit the automations page with status {string}") do |status|
  visit automations_path(status: status)
end

When("I visit the automation details page for {string}") do |template_name|
  automation = Automation.joins(:template)
                         .where(templates: { name: template_name }, user: User.find_by(email: "test@example.com"))
                         .first
  visit automation_path(automation)
end

When("I visit the automation details page for ID {int}") do |id|
  visit automation_path(id)
end

Then("I should see the automation's template name {string}") do |name|
  expect(page).to have_text(name)
end

Then("I should see the automation's status {string}") do |expected_status|
  automation_block = find('div.bg-white.shadow-md', text: "Execution Details")
  status_dd = automation_block.find(:xpath, ".//dt[normalize-space(text())='Status:']/following-sibling::dd[1]//span")
  expect(status_dd.text.strip).to eq(expected_status.capitalize)
end


Then("I should see an error message {string}") do |msg|
  expect(page).to have_text(msg)
end
