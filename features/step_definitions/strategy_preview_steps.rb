When('I send a preview request for the template {string} with an invalid spreadsheet URL') do |template_name|
    template = Template.find_by(name: template_name)

    # Use a URL that will break fetch_spreadsheet_data
    page.driver.submit :post, "/templates/#{template.id}/preview", {
    rules_data: template.rules_data.to_json,
    spreadsheet_url: "https://invalid-url.example.com/broken.csv"
    }

    # Capture the response HTML for parsing
    @response_body = page.driver.response.body
end

Then('I should see a preview error message') do
    expect(@response_body).to include("Name or service not known")
end

When('I send a preview request for the template {string}') do |template_name|
  template = Template.find_by(name: template_name)

  # Use the template's stored spreadsheet URL
  page.driver.submit :post, "/templates/#{template.id}/preview", {
    rules_data: template.rules_data.to_json,
    spreadsheet_url: template.spreadsheet_url
  }

  # Store the response body for assertion
  @response_body = page.driver.response.body
end

Then('I should see the preview results') do
  expect(@response_body).to include("preview_results")
end