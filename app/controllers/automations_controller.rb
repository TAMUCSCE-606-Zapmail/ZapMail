class AutomationsController < ApplicationController
  before_action :authorize

  def index
    # No logging is needed here, as this is a standard view action.
    automations = current_user.automations
                              .includes(:template)
                              .recent

    if params[:status].present? && params[:status] != 'all'
      automations = automations.where(status: params[:status])
    end

    @automations = automations.page(params[:page]).per(10)
  end

  def show
    @automation = current_user.automations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    # --- FIX: Send a warning notification to Slack ---
    # This logs a notable but non-critical event: a user tried to access a record
    # that doesn't exist or doesn't belong to them.
    warning_message = <<~MSG
      *Record Not Found*
      A user tried to access an automation that could not be found.
      *Automation ID:* `#{params[:id]}`
      *User:* `#{current_user&.email}`
    MSG
    SlackNotifierService.new.notify(warning_message, :warning)

    flash[:error] = "The automation you were looking for could not be found."
    redirect_to automations_path
  end
end
