require 'rails_helper'

RSpec.describe User, type: :model do
  subject { described_class.new(name: "Test User", password: "password123", password_confirmation: "password123") }

  context "validations" do
    it "accepts a valid .com email" do
      subject.email = "test@example.com"
      expect(subject).to be_valid
    end

    it "accepts a valid .edu email" do
      subject.email = "student@tamu.edu"
      expect(subject).to be_valid
    end

    it "rejects email without @" do
        subject.email = "invalidemail.com"
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to_not be_empty
    end

    it "rejects email without proper domain" do
        subject.email = "user@example.org"
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to_not be_empty
    end

    it "rejects empty email" do
      subject.email = ""
      expect(subject).not_to be_valid
    end

    it "rejects if password confirmation does not match" do
  user = User.new(
    name: "yifei",
    email: "yifeiwang@tamu.edu",
    password: "newpassword",
    password_confirmation: "wrongpassword"
  )
  expect(user).not_to be_valid
  expect(user.errors[:password_confirmation]).to include("doesn't match Password")
end

#blank password won't overwrite old password
 it "allows profile update without changing password (blank password)" do
      user = User.create!(
        name: "Yifei",
        email: "yifei@example.com",
        password: "password123",
        password_confirmation: "password123"
      )

      user.name = "Updated Name"

      expect(user).to be_valid
      expect(user.authenticate("password123")).to eq(user)  # original password still works
    end
end
end
