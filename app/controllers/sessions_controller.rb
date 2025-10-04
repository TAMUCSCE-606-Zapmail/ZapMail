class SessionsController < ApplicationController
  # GET /login
  def new
    # No logging needed here, as this is a routine action.
  end

  # POST /login
  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user && user.authenticate(params[:session][:password])
      # Successful login
      token = encode_token({ user_id: user.id })
      cookies[:jwt] = { value: token, httponly: true, expires: 24.hours.from_now }
      flash[:success] = "You have successfully logged in."

      # --- FIX: Send a success notification to Slack ---
      SlackNotifierService.new.notify(
        "User logged in: `#{user.email}`",
        :success
      )

      redirect_to templates_path # Redirect to templates dashboard after login
    else
      # Failed login
      flash.now[:error] = "Invalid email or password."

      # --- FIX: Send a warning notification to Slack ---
      SlackNotifierService.new.notify(
        "Failed login attempt for email: `#{params[:session][:email].downcase}`",
        :warning
      )

      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /logout
  def destroy
    # Capture the user's email before they are logged out
    user_email = current_user&.email

    cookies.delete(:jwt)
    flash[:success] = "You have successfully logged out."
    
    # --- FIX: Send an info notification to Slack ---
    if user_email
      SlackNotifierService.new.notify("User logged out: `#{user_email}`")
    end

    redirect_to root_path
  end
end
