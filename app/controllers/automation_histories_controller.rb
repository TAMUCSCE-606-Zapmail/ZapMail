class AutomationHistoriesController < ApplicationController
  def index
    scope = AutomationHistory
              .joins(automation: :strategy)
              .where(strategies: { user_id: current_user.id })
              .order(created_at: :desc)

    @pagy, @automation_histories = pagy(scope)
  end
end