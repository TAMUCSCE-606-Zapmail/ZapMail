class Automation < ApplicationRecord
  belongs_to :template
  belongs_to :user

  validates :status, presence: true
  validates :send_at, presence: true
  validates :action_data, presence: true

  scope :scheduled, -> { where(status: 'scheduled', enabled: true) }
  scope :due_to_run, -> { scheduled.where("send_at <= ?", Time.current) }
end
class Automation < ApplicationRecord
  belongs_to :template
  belongs_to :user

  validates :status, presence: true
  validates :send_at, presence: true
  validates :action_data, presence: true

  scope :scheduled, -> { where(status: 'scheduled', enabled: true) }
  scope :due_to_run, -> { scheduled.where("send_at <= ?", Time.current) }

  # New scopes for history page
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(send_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }
  
  # Helper method to check if automation has executed
  def executed?
    %w[completed failed].include?(status)
  end
  
  # Get execution timestamp
  def executed_at
    updated_at if executed?
  end
end
