class AddAirbnbPublicUrlToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :airbnb_public_url, :string
  end
end
