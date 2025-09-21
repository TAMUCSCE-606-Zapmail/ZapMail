class Automation < ApplicationRecord
  belongs_to :strategy
  has_many :automation_histories, dependent: :destroy
end
