# features/step_definitions/login_steps.rb
require 'capybara/rails'

Given("a user exists with email {string} and password {string}") do |email, password|
  User.create!(name: "Test User", email: email, password: password, password_confirmation: password)
  @start_time = Time.now   # store start time
end

When ('I visit the login page') do
  visit '/login'
end

When('I submit valid credentials') do
  fill_in 'Email', with: 'test@example.com'
  fill_in 'Password', with: 'password123'
  find('input[type="submit"][value="Log In"]').click
end

Then('I should see my dashboard') do
  expect(page).to have_current_path('/templates')
  expect(page).to have_content('Your Templates')
end

Then('the login process should complete within 2 seconds') do
  end_time = Time.now
  duration = end_time - @start_time
  expect(duration).to be < 2.0
end

When("I visit the templates page") do
  visit templates_path
end

When("I visit a page that raises an unhandled exception") do
  visit "/raise_error_test"
end

When("I log in as {string} with password {string}") do |email, password|
  visit login_path
  fill_in "Email", with: email
  fill_in "Password", with: password
  click_button "Log In"
end

Then("I should be redirected to the login page") do
  expect(page).to have_current_path(login_path)
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should be on the templates page") do
  expect(page).to have_current_path(templates_path)
end

And("I should be on the login page") do
  expect(page).to have_current_path(login_path)
end

When("I visit the protected test page") do
  visit "/protected_test"
end

Then("I should see an authorization error") do
  expect(page).to have_content("You must be logged in to access this page.")
end

Given("Slack notifications are disabled") do
  class SlackNotifierService
    def notify(*args)
      # just capture calls if you want
      $fake_slack_notifier ||= []
      $fake_slack_notifier << args
    end
  end
end

When("I log out") do
  find('button[title="Logout"]').click
end

Then("my JWT cookie should be cleared") do
  cookie = page.driver.browser.rack_mock_session.cookie_jar["jwt"]
  raise "JWT cookie still exists!" if cookie.present?
end

Then("I should see a flash message {string}") do |message|
  expect(page).to have_content(message)
end

Then("Slack should be notified of the logout for {string}") do |email|
  found = $fake_slack_notifier.any? do |args|
    args.any? { |arg| arg.to_s.include?(email) }
  end
  raise "No Slack message for user logout!" unless found
end

Then("I should be redirected to the home page") do
  expect(page).to have_current_path(root_path)
end