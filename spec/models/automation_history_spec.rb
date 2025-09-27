# spec/models/automation_history_spec.rb
require "rails_helper"

RSpec.describe AutomationHistory, type: :model do
  describe ".search" do
    # --- FIX: Create a user so strategy validation passes ---
    let!(:user) { User.create!(email: "tester@example.com", password: "password123") }

    let!(:strategy) do
      Strategy.create!(name: "My Special Strategy", user: user)
    end

    let!(:automation) do
      Automation.create!(strategy: strategy)
    end

    let!(:log1) do
      AutomationHistory.create!(
        automation: automation,
        row_data: { "email" => "test_user@gmail.com" },
        api_response: "Success response",
        error_message: nil
      )
    end

    let!(:log2) do
      AutomationHistory.create!(
        automation: automation,
        row_data: { "email" => "other@example.com" },
        api_response: "Another response",
        error_message: "Some error occurred"
      )
    end

    it "returns all records when query is blank" do
      results = AutomationHistory.search(nil)
      expect(results).to include(log1, log2)
    end

    it "matches by email" do
      results = AutomationHistory.search("gmail.com")
      expect(results).to include(log1)
      expect(results).not_to include(log2)
    end

    it "matches by api_response" do
      results = AutomationHistory.search("another")
      expect(results).to include(log2)
      expect(results).not_to include(log1)
    end

    it "matches by error_message" do
      results = AutomationHistory.search("error")
      expect(results).to include(log2)
      expect(results).not_to include(log1)
    end

    it "matches by strategy name" do
      results = AutomationHistory.search("special")
      expect(results).to include(log1, log2)
    end

    it "is case-insensitive" do
      results = AutomationHistory.search("GMAIL.COM")
      expect(results).to include(log1)
    end
  end
end