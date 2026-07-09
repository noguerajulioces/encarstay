class Admin::SubscribersController < Admin::BaseController
  def index
    @counts = Subscriber.group(:status).count
    @subscribers = Subscriber.chronologically
    @subscribers = @subscribers.where(status: params[:status]) if params[:status].present?

    respond_to do |format|
      format.html
      format.csv { send_data Subscriber.to_csv, filename: "subscribers-#{Date.current}.csv", type: "text/csv" }
    end
  end

  def destroy
    Subscriber.find(params[:id]).destroy
    redirect_to admin_subscribers_path(status: params[:status]), notice: "Suscriptor eliminado."
  end

  # Manual redemption of the welcome discount, toggled when the code is applied
  # during WhatsApp/deposit coordination.
  def redeem
    subscriber = Subscriber.find(params[:id])
    subscriber.update(discount_redeemed_at: subscriber.discount_redeemed_at ? nil : Time.current)
    redirect_to admin_subscribers_path(status: params[:status]), notice: "Descuento actualizado."
  end
end
