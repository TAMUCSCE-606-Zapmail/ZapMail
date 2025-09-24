class AutomationHistoriesController < ApplicationController
  def index
    @automation_histories = AutomationHistory
      .joins(automation: :strategy)
      .where(strategies: { user_id: current_user.id })
      .order(created_at: :desc)
  end
end
