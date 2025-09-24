class AutomationHistoriesController < ApplicationController
  def index
    per_page = 25
    page = params.fetch(:page, 1).to_i
    page = 1 if page < 1

    base = AutomationHistory
      .joins(automation: :strategy)
      .where(strategies: { user_id: current_user.id })

    @total_count  = base.count
    @total_pages  = (@total_count.to_f / per_page).ceil
    @page         = [page, @total_pages.zero? ? 1 : @total_pages].min

    @automation_histories = base
      .order(created_at: :desc)
      .limit(per_page)
      .offset((@page - 1) * per_page)
  end
end