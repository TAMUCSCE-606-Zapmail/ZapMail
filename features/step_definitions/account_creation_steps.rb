When("I visit the signup page") do
  visit "/signup"
end

When("I submit the signup form") do
  click_button "Create Account"
end

When("I submit the signup form without filling in required fields") do
  click_button "Create Account"
end

Then("a user with email {string} should exist") do |email|
  expect(User.find_by(email: email)).not_to be_nil
end

When("I fill in {string} with {string}") do |field_name, value|
  field_id_map = {
    "Name" => "user_name",
    "Email" => "user_email",
    "Password" => "user_password",
    "Password confirmation" => "user_password_confirmation"
  }

  fill_in field_id_map[field_name], with: value
end

Then("I should see an error message about missing fields") do
  # Look for any browser validation message
  expect(
    page.has_content?("Please fill out this field") ||
    page.has_content?("can't be blank")
  ).to be true
end

Then("no user should be created") do
  expect(User.find_by(email: "test@example.com")).to be_nil
end
