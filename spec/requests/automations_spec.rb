require 'rails_helper'

RSpec.describe "Automations", type: :request do
  let(:user) { User.create!(name: "Test", email: "test@example.com", password: "password123") }
  # let(:token) { JwtService.encode(user_id: user.id) }

  # describe "GET /index" do
  #   it "returns http success" do
  #     get "/automations", headers: { "Authorization" => "Bearer #{token}" }
  #     expect(response).to have_http_status(:success)
  #   end
  # end

  describe "GET /show" do
    it "returns http success" do
      get "/automations/show"
      expect(response).to have_http_status(:success)
    end
  end

end
