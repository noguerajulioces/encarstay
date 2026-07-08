class Admin::GuideEntriesController < Admin::BaseController
  before_action :set_guide_entry, only: %i[ edit update destroy ]

  def index
    @kind = GuideEntry::KINDS.include?(params[:kind]) ? params[:kind] : "event"
    @guide_entries = GuideEntry.where(kind: @kind).ordered
    @counts = GuideEntry.group(:kind).count
  end

  def new
    @guide_entry = GuideEntry.new(kind: kind_param)
  end

  def create
    @guide_entry = GuideEntry.new(guide_entry_params)
    if @guide_entry.save
      attach_cover
      redirect_to edit_admin_guide_entry_path(@guide_entry), notice: "Contenido creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @properties = Property.alphabetically
  end

  def update
    if @guide_entry.update(guide_entry_params)
      attach_cover
      redirect_to edit_admin_guide_entry_path(@guide_entry), notice: "Cambios guardados."
    else
      @properties = Property.alphabetically
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    kind = @guide_entry.kind
    @guide_entry.destroy
    redirect_to admin_guide_entries_path(kind: kind), notice: "Contenido eliminado."
  end

  private
    def kind_param
      GuideEntry::KINDS.include?(params[:kind]) ? params[:kind] : "attraction"
    end

    def set_guide_entry
      @guide_entry = GuideEntry.find_by!(slug: params[:id])
    end

    def attach_cover
      @guide_entry.cover_image.attach(params[:cover_image]) if params[:cover_image].present?
    end

    def guide_entry_params
      params.require(:guide_entry).permit(
        :kind, :category_id, :title_es, :title_en, :title_pt,
        :summary_es, :summary_en, :summary_pt,
        :description_es, :description_en, :description_pt,
        :schedule_note_es, :schedule_note_en, :schedule_note_pt,
        :starts_at, :ends_at, :recurring, :address, :area,
        :latitude, :longitude, :external_url, :featured, :published, :position
      )
    end
end
