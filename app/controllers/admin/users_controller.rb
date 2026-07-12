class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: %i[ edit update destroy ]

  def index
    @users = User.alphabetically
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to admin_users_path, notice: "Usuario administrador creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: "Usuario administrador actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.removable_by?(Current.user)
      @user.destroy!
      redirect_to admin_users_path, notice: "Usuario administrador eliminado."
    else
      redirect_to admin_users_path, alert: "No podés eliminar el usuario con el que estás conectado."
    end
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      permitted = params.require(:user).permit(:name, :email, :password, :password_confirmation)
      permitted.delete(:password) if permitted[:password].blank?
      permitted.delete(:password_confirmation) if permitted[:password_confirmation].blank?
      permitted
    end
end
