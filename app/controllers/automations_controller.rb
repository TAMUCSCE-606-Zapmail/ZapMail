class AutomationsController < ApplicationController
  before_action :authorize

  def index
    @automations = current_user.automations
                               .includes(:template)
                               .recent

    # Filter by status if provided
    if params[:status].present? && params[:status] != 'all'
      @automations = @automations.where(status: params[:status])
    end
  end

  def show
    @automation = current_user.automations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Automation not found"
    redirect_to automations_path
  end
end
