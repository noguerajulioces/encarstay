class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :require_admin

  private
    def require_admin
      Current.user = User.find_by(id: session[:user_id])
      redirect_to new_admin_session_path, alert: "Iniciá sesión para continuar." unless Current.user
    end
end
