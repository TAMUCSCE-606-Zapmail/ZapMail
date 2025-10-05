require 'rails_helper'

RSpec.describe "Automations", type: :request do
  let(:user) { User.create!(name: "Test User", email: "test@example.com", password: "password123", password_confirmation: "password123") }
  let(:token) { JWT.encode({ user_id: user.id, exp: 24.hours.from_now.to_i }, ENV.fetch("JWT_SECRET_KEY"), 'HS256') }

  let!(:template) { user.templates.create!(name: "Test Template", spreadsheet_url: "https://example.com", rules_data: { columns: [], rules: [] }) }
  let!(:automation) { user.automations.create!(template: template, status: "completed", send_at: 2.hours.ago, enabled: true, action_data: { to: "test@example.com" }) }

  describe "GET /index" do
    it "returns http success" do
      get "/automations", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/automations/#{automation.id}", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:success)
    end
  end

end
