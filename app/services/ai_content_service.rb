class AiContentService
    def initialize
      # The client is configured in the initializer, so we can create a new instance here.
      @client = OpenAI::Client.new
    end
  
    def generate(subject:, body:)
      # Construct a clear, detailed prompt for the AI.
      # This guides the AI to produce a response in the format we want.
      prompt = <<~PROMPT
        You are an expert copywriter for a university. Your task is to take a template for an email subject and body and rewrite them to be more professional, engaging, and friendly.
  
        Return your response as a single JSON object with two keys: "subject" and "body".
  
        Here are the templates:
        Subject Template: "#{subject}"
        Body Template: "#{body}"
      PROMPT
  
      begin
        # Make the API call to the OpenAI Chat completions endpoint.
        # We use the gpt-4o model, which is powerful and cost-effective.
        response = @client.chat(
          parameters: {
            model: "gpt-4o",
            messages: [{ role: "user", content: prompt }],
            temperature: 0.7, # A value between 0 and 1. Higher is more creative.
            response_format: { type: "json_object" } # Ensures the response is valid JSON
          }
        )
  
        # Extract the JSON content from the AI's response.
        json_response = response.dig("choices", 0, "message", "content")
        parsed_response = JSON.parse(json_response)
  
        # Return the generated subject and body, stripping any extra whitespace.
        {
          subject: parsed_response["subject"].strip,
          body: parsed_response["body"].strip
        }
  
      rescue StandardError => e
        # If the AI call fails for any reason (e.g., API is down, invalid key),
        # log the error and fall back to using the original, unedited content.
        # This makes your application resilient.
        Rails.logger.error "AI Content Generation Failed: #{e.message}"
        {
          subject: subject,
          body: body
        }
      end
    end
  end
  