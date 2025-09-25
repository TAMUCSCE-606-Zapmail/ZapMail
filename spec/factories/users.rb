# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { "user#{rand(1000)}@example.com" }
    password { "password123" }
  end
end

# spec/factories/strategies.rb
FactoryBot.define do
  factory :strategy do
    name { "Test Strategy" }
    csv_file_path { "/tmp/test.csv" }
    association :user
  end
end
