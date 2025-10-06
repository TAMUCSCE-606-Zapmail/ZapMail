ai_service_response = nil

Given("I have a subject template {string}") do |subject|
  @subject_template = subject
end

Given("I have a body template {string}") do |body|
  @body_template = body
end

Given("the AI client is stubbed to raise an error") do
  allow_any_instance_of(OpenAI::Client).to receive(:chat).and_raise(StandardError, "API failure")
end

When("I request AI-generated content") do
  service = AiContentService.new
  ai_service_response = service.generate(subject: @subject_template, body: @body_template)
end

Then("I should receive a response with a subject and body") do
  expect(ai_service_response[:subject]).not_to be_nil
  expect(ai_service_response[:body]).not_to be_nil
end

Then("the subject should not be the same as the original") do
  expect(ai_service_response[:subject]).not_to eq(@subject_template)
end

Then("the body should not be the same as the original") do
  expect(ai_service_response[:body]).not_to eq(@body_template)
end

Then("I should receive a response with the original subject and body") do
  expect(ai_service_response[:subject]).to eq(@subject_template)
  expect(ai_service_response[:body]).to eq(@body_template)
end
