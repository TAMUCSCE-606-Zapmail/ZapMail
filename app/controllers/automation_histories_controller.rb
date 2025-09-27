class AutomationHistoriesController < ApplicationController
  def index
    @query = params[:query]

    scope = AutomationHistory
              .joins(automation: :strategy)
              .where(strategies: { user_id: current_user.id })
              .search(@query)   # 🔍 apply search here
              .order(created_at: :desc)

    @pagy, @automation_histories = pagy(scope)
  end
end