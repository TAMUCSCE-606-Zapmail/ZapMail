require 'rails_helper'

RSpec.describe AiContentService do
  let(:service) { described_class.new }
  let(:client) { instance_double(OpenAI::Client) }
  let(:slack_service) { instance_double(SlackNotifierService) }

  before do
    allow(OpenAI::Client).to receive(:new).and_return(client)
    allow(SlackNotifierService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:notify)
  end

  describe '#generate' do
    let(:subject_text) { 'Test Subject {name}' }
    let(:body_text) { 'Hello {name}, welcome!' }

    context 'successful AI generation' do
      let(:ai_response) do
        {
          'choices' => [ {
            'message' => {
              'content' => '{"subject":"Enhanced Subject","body":"Enhanced body text"}'
            }
          } ]
        }
      end

      before { allow(client).to receive(:chat).and_return(ai_response) }

      it 'generates AI content' do
        result = service.generate(subject: subject_text, body: body_text)
        expect(result[:subject]).to eq('Enhanced Subject')
        expect(result[:body]).to eq('Enhanced body text')
      end

      it 'calls OpenAI with correct parameters' do
        expect(client).to receive(:chat).with(
          parameters: hash_including(
            model: 'gpt-4o',
            messages: array_including(hash_including(role: 'user')),
            temperature: 0.7,
            response_format: { type: 'json_object' }
          )
        )
        service.generate(subject: subject_text, body: body_text)
      end
    end

    context 'AI service fails' do
      before do
        allow(client).to receive(:chat).and_raise(StandardError, 'API timeout')
        allow(Rails.logger).to receive(:error)
      end

      it 'falls back to original content' do
        result = service.generate(subject: subject_text, body: body_text)
        expect(result[:subject]).to eq(subject_text)
        expect(result[:body]).to eq(body_text)
      end

      it 'sends Slack warning' do
        expect(slack_service).to receive(:notify).with(/AI content generation failed/, :warning)
        service.generate(subject: subject_text, body: body_text)
      end

      it 'logs error' do
        expect(Rails.logger).to receive(:error).with(/AI Content Generation Failed/)
        service.generate(subject: subject_text, body: body_text)
      end
    end
  end
end
