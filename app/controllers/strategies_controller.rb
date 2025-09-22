class StrategiesController < ApplicationController
  before_action :set_strategy, only: %i[show edit update destroy]

  def index
    @strategies = current_user.strategies.includes(:rules, :automations => :automation_histories)
  end

  def show
  end

  def new
    @strategy = current_user.strategies.build
  end

  def create
    @strategy = current_user.strategies.build(strategy_params)
    if @strategy.save
      redirect_to @strategy, notice: "Strategy created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @strategy.update(strategy_params)
      redirect_to @strategy, notice: "Strategy updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @strategy.destroy
    redirect_to strategies_path, notice: "Strategy deleted successfully."
  end

  private

  def set_strategy
    @strategy = current_user.strategies.find(params[:id])
  end

  def strategy_params
    params.require(:strategy).permit(:name, :csv_file_path)
  end
end
