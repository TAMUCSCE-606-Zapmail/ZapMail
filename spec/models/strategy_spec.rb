require 'rails_helper'

RSpec.describe Strategy, type: :model do
    it { should belong_to(:user) }
    it { should have_many(:rules).dependent(:destroy) }
    it { should have_many(:automations).dependent(:destroy) }
end
