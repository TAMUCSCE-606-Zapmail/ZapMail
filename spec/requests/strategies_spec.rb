require 'rails_helper'

RSpec.describe "Strategies", type: :request do
  let(:user) { create(:user) }
  let!(:strategy1) { create(:strategy, user: user) }
  let!(:strategy2) { create(:strategy, user: user) }

    before do
        login_as(user, scope: :user)
    end


    describe "GET /strategies" do
        it "returns http success" do
            get strategies_path
            expect(response).to have_http_status(:success)
        end

        it "assigns @strategies to current user's strategies" do
            get strategies_path
            # parse the response body to check for strategy names
            expect(response.body).to include(strategy1.name)
        end

        it "includes all current user's strategies" do
            get strategies_path
            expect(response.body).to include(strategy2.name)
        end
    end
end
