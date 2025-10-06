class ErrorsController < ApplicationController
  def raise_test
    raise StandardError, "Test error"
  end
end
