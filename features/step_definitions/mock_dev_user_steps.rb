Given("Rails is in development mode") do
  allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
end

Given("there is no user in the database") do
  User.destroy_all
  expect(User.count).to eq(0)
end

When("the user visits the root page") do
  visit root_path
end

Then("a user should be created") do
  expect(User.count).to eq(1)
end

Then("the user should be signed in") do
  # Example: check that the page shows a logout link
  expect(page).to have_content("Log Out")
end
