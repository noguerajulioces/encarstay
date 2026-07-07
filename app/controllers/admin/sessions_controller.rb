class Admin::SessionsController < ApplicationController
  layout "admin"

  def new
  end

  def create
    user = User.authenticate_by(email: params[:email].to_s.strip.downcase, password: params[:password])
    if user
      reset_session
      session[:user_id] = user.id
      redirect_to admin_root_path, notice: "Bienvenido, #{user.name}."
    else
      flash.now[:alert] = "Email o contraseña incorrectos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to new_admin_session_path, notice: "Sesión cerrada."
  end
end
