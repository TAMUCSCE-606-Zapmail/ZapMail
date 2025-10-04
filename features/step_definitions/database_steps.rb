require 'active_record'

Given('the Rails environment is loaded') do
  # Rails environment is already loaded by cucumber/rails in env.rb
  # This step is just a documentation step to make the feature readable
  # We can verify it's loaded by checking if Rails is defined
  expect(defined?(Rails)).to be_truthy
end


Given('a sample user record is created in the database') do
  @user = User.create!(
    name: 'Test User',
    email: 'testuser@example.com',
    password: 'password123'
  )
end


When('I check the database connection') do
  begin
    @connected = ActiveRecord::Base.connection.active?
  rescue StandardError => e
    @connected = false
    puts "Database connection error: #{e.message}"
  end
end

Then('the connection should be successful') do
  expect(@connected).to be true
end

When('I query the schema version') do
  @schema_version = ActiveRecord::Base.connection.select_value(
    'SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1'
  )
end

Then('it should not be empty') do
  expect(@schema_version).not_to be_nil
  expect(@schema_version).not_to eq('')
end


When('I retrieve that record') do
  @fetched_user = User.find_by(email: 'testuser@example.com')
end

Then('it should match the original data') do
  expect(@fetched_user).not_to be_nil
  expect(@fetched_user.email).to eq(@user.email)
end
