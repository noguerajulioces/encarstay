class AddAirbnbListingUrlToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :airbnb_listing_url, :string
  end
end
