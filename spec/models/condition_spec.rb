# spec/models/condition_spec.rb
require 'rails_helper'

RSpec.describe Condition, type: :model do
    it "belongs to a rule" do
        rule = create(:rule)                    # use existing rule factory
        condition = create(:condition, rule: rule)

        # Access the association to cover belongs_to
        expect(condition.rule).to eq(rule)
    end
end
