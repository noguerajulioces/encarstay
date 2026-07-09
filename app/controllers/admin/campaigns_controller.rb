class Admin::CampaignsController < Admin::BaseController
  before_action :set_campaign, only: %i[ show edit update destroy deliver ]

  def index
    @campaigns = Campaign.chronologically
    @confirmed_count = Subscriber.confirmed.count
  end

  def show
  end

  def new
    @campaign = Campaign.new
  end

  def create
    @campaign = Campaign.new(campaign_params)
    if @campaign.save
      redirect_to admin_campaign_path(@campaign), notice: "Campaña creada."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    return redirect_to admin_campaign_path(@campaign), alert: "Una campaña enviada no se puede editar." unless @campaign.editable?
  end

  def update
    return redirect_to admin_campaign_path(@campaign), alert: "Una campaña enviada no se puede editar." unless @campaign.editable?

    if @campaign.update(campaign_params)
      redirect_to admin_campaign_path(@campaign), notice: "Campaña actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @campaign.destroy
    redirect_to admin_campaigns_path, notice: "Campaña eliminada."
  end

  # Launch the blast to all confirmed subscribers.
  def deliver
    if @campaign.deliver!
      redirect_to admin_campaign_path(@campaign), notice: "Envío en curso a los suscriptores confirmados."
    else
      redirect_to admin_campaign_path(@campaign), alert: "Esta campaña ya fue enviada."
    end
  end

  private
    def set_campaign
      @campaign = Campaign.find(params[:id])
    end

    def campaign_params
      params.require(:campaign).permit(:subject, :body)
    end
end
