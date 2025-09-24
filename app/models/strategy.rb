class Strategy < ApplicationRecord
  belongs_to :user
  has_many :rules, dependent: :destroy
  has_many :automations, dependent: :destroy
end
