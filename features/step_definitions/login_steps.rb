# features/step_definitions/login_steps.rb
require 'capybara/rails'

Given('I am on the login page') do
  visit '/login'
  expect(page).to have_content('Log in')
end

When('I submit valid credentials') do
  fill_in 'Email', with: 'testuser@example.com'
  fill_in 'Password', with: 'password123'
  click_button 'Log in'
end

Then('I should see my dashboard') do
  expect(page).to have_current_path('/dashboard', ignore_query: true)
  expect(page).to have_content('Dashboard')
end

Then('the login process should complete within 2 seconds') do
  start_time = Time.now
  visit '/login'
  fill_in 'Email', with: 'testuser@example.com'
  fill_in 'Password', with: 'password123'
  click_button 'Log in'
  duration = Time.now - start_time
  expect(duration).to be < 2.0
end
