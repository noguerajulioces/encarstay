class AddImageCreditToGuideEntries < ActiveRecord::Migration[8.1]
  def change
    # Atribución de la foto de portada (autor + licencia, ej. Wikimedia Commons).
    add_column :guide_entries, :image_credit, :string
  end
end
