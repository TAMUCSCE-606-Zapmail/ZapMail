require 'net/http'
require 'uri'

When('I visit the login page') do
  @login_url = URI("#{@heroku_url}/login")
  @login_start_time = Time.now
  @response = Net::HTTP.get_response(@login_url)
  @login_page_loaded = @response.code.to_i == 200
end

When('I submit valid credentials') do
  uri = URI("#{@heroku_url}/login")
  req = Net::HTTP::Post.new(uri)
  req.set_form_data({
    'session[email]' => 'testuser@example.com',      # ✅ 必须是 session[email]
    'session[password]' => 'password123'             # ✅ 必须是 session[password]
  })

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  @dashboard_response = http.request(req)
  @login_duration = Time.now - @login_start_time
end

Then('I should see my dashboard') do
  expect(@dashboard_response.code.to_i).to eq(200)
  expect(@dashboard_response.body).to include('Dashboard')
end

Then('the login process should complete within 2 seconds') do
  expect(@login_duration).to be < 2.0
end
