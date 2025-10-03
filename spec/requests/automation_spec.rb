require 'rails_helper'

RSpec.describe "Automations", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/automation/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/automation/show"
      expect(response).to have_http_status(:success)
    end
  end

end
