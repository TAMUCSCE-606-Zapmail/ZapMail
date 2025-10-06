class TestController < ApplicationController
  before_action :authorize

  def protected_action
  end
end
