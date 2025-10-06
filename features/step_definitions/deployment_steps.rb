require 'net/http'

Given('the Heroku app URL is set') do
    @heroku_url = 'https://zapmail-pradeep-a162d897f0b7.herokuapp.com/'
end

When('I send a request to the app') do
  uri = URI(@heroku_url)
  response = Net::HTTP.get_response(uri)
  @status_code = response.code.to_i
  @body = response.body
end

Then('I should receive a successful response') do
  expect(@status_code).to eq(200)
end

When('I visit the home page') do
  uri = URI(@heroku_url)
  @response_body = Net::HTTP.get(uri)
end

Then('I should see the application title') do
  expect(@response_body).to include('ZapMail')
end
