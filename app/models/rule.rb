class Rule < ApplicationRecord
  belongs_to :strategy
  has_many :conditions, dependent: :destroy
  has_many :strategy_actions, dependent: :destroy
end
