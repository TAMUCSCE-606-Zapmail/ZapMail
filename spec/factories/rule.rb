FactoryBot.define do
    factory :rule do
        association :strategy      # links rule to a strategy
        order { 1 }               # default order
    end
end

# spec/factories/strategy_actions.rb
FactoryBot.define do
    factory :strategy_action do
        association :rule
    end
end
