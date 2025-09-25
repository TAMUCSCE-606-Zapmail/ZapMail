Given("a signed-in user") do
  @user = FactoryBot.create(:user)
  visit new_user_session_path     # Devise login page
  fill_in "Email", with: @user.email
  fill_in "Password", with: @user.password
  click_button "Log in"

  # Verify login success (e.g., logout link or user email displayed)
  expect(page).to have_content("Logout").or have_content(@user.email)
end


Given("the user has {int} strategies") do |count|
  count.times do |i|
    FactoryBot.create(:strategy, name: "Strategy #{i+1}", user: @user)
  end
end

When("the user visits the strategies page") do
  visit strategies_path
end

Then("they should see the {int} strategies listed") do |count|
  expect(page).to have_selector('.strategy', count: count)
end

When('they click the "+ New strategy" button') do
  click_button "+ New strategy"
end

Then("they should be on the new strategy page") do
  expect(page).to have_current_path(new_strategy_path)
end
