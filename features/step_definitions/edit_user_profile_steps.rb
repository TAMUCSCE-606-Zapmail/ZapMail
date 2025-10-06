When("I visit the edit profile page") do
  visit '/profile/edit'
end

When("I submit the profile form") do
  find('input[type="submit"][value="Update Profile"]').click
end

Then("the user's name should be {string}") do |expected_name|
  user = User.find_by(email: "updated@example.com") || User.find_by(email: "test@example.com")
  expect(user.name).to eq(expected_name)
end

Then("the user's email should be {string}") do |expected_email|
  user = User.find_by(email: expected_email) || User.find_by(email: "test@example.com")
  expect(user.email).to eq(expected_email)
end
