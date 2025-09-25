require 'rails_helper'

RSpec.describe "MockDevUser", type: :request do
    include Warden::Test::Helpers

    before(:each) do
        Warden.test_mode!
    end

    after(:each) do
        Warden.test_reset!
    end

    it "creates and signs in a user in development" do
        # Force Rails.env to development
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))

        # Ensure no users exist
        expect(User.count).to eq(0)

        # Hit a route handled by ApplicationController
        get root_path

        # The user should now exist
        user = User.first
        expect(user).not_to be_nil

        # Check if the user is signed in
        warden = request.env['warden']
        expect(warden.authenticated?(:user)).to be true
        expect(warden.user(:user)).to eq(user)
    end
end
