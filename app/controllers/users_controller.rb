class UsersController < ApplicationController
  before_action :authorize, only: [ :show, :edit, :update ]
  before_action :set_user, only: [ :show, :edit, :update ]

  # GET /signup
  def new
    @user = User.new
  end

  # POST /users
  def create
    @user = User.new(user_params)
    if @user.save
      # --- Send a success notification to Slack ---
      # FIX: Changed 'user.email' to '@user.email'
      SlackNotifierService.new.notify(
        "🎉 New user signed up: `#{@user.email}`.",
        :success
      )

      # Automatically log in the user after signup
      token = encode_token({ user_id: @user.id })
      cookies[:jwt] = { value: token, httponly: true, expires: 24.hours.from_now }
      flash[:success] = "Welcome to the ZapMail! Your account was created successfully."
      redirect_to templates_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /profile
  def show
    # @user is set by set_user
  end

  # GET /profile/edit
  def edit
    # @user is set by set_user
  end

  # PATCH /profile
  def update
    if @user.update(user_params)
      # --- Send an info notification to Slack ---
      SlackNotifierService.new.notify("User `#{current_user.email}` updated their profile.")

      flash[:success] = "Your profile has been updated successfully."
      redirect_to profile_path
    else
      # --- Send a warning notification to Slack ---
      SlackNotifierService.new.notify(
        "User `#{current_user.email}` failed to update their profile. Errors: `#{@user.errors.full_messages.join(', ')}`",
        :warning
      )
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    permitted = params.require(:user).permit(
      :name,
      :email,
      :password,
      :password_confirmation,
      :date_of_birth,
      :major,
      :classification,
      :uin
    )

    # If password fields are left blank, don’t include them in the update
    if permitted[:password].blank? && permitted[:password_confirmation].blank?
      permitted.delete(:password)
      permitted.delete(:password_confirmation)
    end

    permitted
  end
end
