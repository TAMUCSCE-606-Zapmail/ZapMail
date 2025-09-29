class Automation < ApplicationRecord
  belongs_to :template
  belongs_to :user

  validates :status, presence: true
  validates :send_at, presence: true
  validates :action_data, presence: true

  scope :scheduled, -> { where(status: 'scheduled', enabled: true) }
  scope :due_to_run, -> { scheduled.where("send_at <= ?", Time.current) }
end
