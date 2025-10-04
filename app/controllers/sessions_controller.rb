# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
    # GET /login
    def new
    end
  
    # POST /login
    def create
      user = User.find_by(email: params[:session][:email].downcase)
      if user && user.authenticate(params[:session][:password])
        # Successful login: create token and store in cookie
        token = encode_token({ user_id: user.id })
        cookies[:jwt] = { value: token, httponly: true, expires: 24.hours.from_now }
        flash[:success] = "You have successfully logged in."
        redirect_to profile_path
      else
        # Failed login
        flash.now[:error] = "Invalid email or password."
        render :new, status: :unprocessable_entity
      end
    end
  
    # DELETE /logout
    def destroy
      cookies.delete(:jwt)
      flash[:success] = "You have successfully logged out."
      redirect_to root_path
    end
  end