class Admin::SettingsController < Admin::BaseController
  before_action :set_setting

  def edit
  end

  def update
    if @setting.update(setting_params)
      redirect_to edit_admin_settings_path, notice: "Configuración guardada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_setting
      @setting = Setting.current
    end

    def setting_params
      params.require(:setting).permit(:whatsapp_number)
    end
end
