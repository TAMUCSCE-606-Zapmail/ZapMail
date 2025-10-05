class AiContentService
    def initialize
      # In a real application, you would initialize your AI client here
      # e.g., @client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
      @client = OpenAI::Client.new
    end
  
    def generate(subject:, body:)
      # Construct a clear, detailed prompt for the AI.
      prompt = <<~PROMPT
        You are an expert copywriter for a university. Your task is to take a template for an email subject and body and rewrite them to be more professional, engaging, and friendly.
  
        Return your response as a single JSON object with two keys: "subject" and "body".
  
        Here are the templates:
        Subject Template: "#{subject}"
        Body Template: "#{body}"
      PROMPT
  
      begin
        # Make the API call to the OpenAI Chat completions endpoint.
        response = @client.chat(
          parameters: {
            model: "gpt-4o",
            messages: [{ role: "user", content: prompt }],
            temperature: 0.7,
            response_format: { type: "json_object" }
          }
        )
  
        # Extract the JSON content from the AI's response.
        json_response = response.dig("choices", 0, "message", "content")
        parsed_response = JSON.parse(json_response)
  
        # Return the generated subject and body.
        {
          subject: parsed_response["subject"].strip,
          body: parsed_response["body"].strip
        }
  
      rescue StandardError => e
        # --- FIX: Send a warning notification to Slack ---
        # This is a non-critical error, so we log it as a warning and continue.
        SlackNotifierService.new.notify(
          "AI content generation failed. Falling back to original content. Error: `#{e.message}`",
          :warning
        )
  
        # Also log the error to the standard Rails logger for more detail.
        Rails.logger.error "AI Content Generation Failed: #{e.message}"
        
        # Fall back to using the original, unedited content.
        {
          subject: subject,
          body: body
        }
      end
    end
  end
  