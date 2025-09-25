# spec/factories/conditions.rb
FactoryBot.define do
    factory :condition do
        association :rule
    end
end
