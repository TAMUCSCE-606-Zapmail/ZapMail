require 'capybara/cucumber'
require 'selenium-webdriver'

Selenium::WebDriver::Chrome::Service.driver_path = '/usr/bin/chromedriver'

Capybara.register_driver :selenium_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.binary = '/usr/bin/chromium-browser'  # set to the path from `which chromium-browser`
  options.add_argument('--headless')           # runs in background
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')         # often needed on Linux
  options.add_argument('--disable-dev-shm-usage')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
