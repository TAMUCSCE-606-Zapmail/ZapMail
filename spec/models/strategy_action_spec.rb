# spec/models/strategy_action_spec.rb
require 'rails_helper'

RSpec.describe StrategyAction, type: :model do
    it "belongs to a rule" do
        rule = create(:rule)                       # uses updated factory
        action = create(:strategy_action, rule: rule)

        # Access the association
        expect(action.rule).to eq(rule)
    end
end
