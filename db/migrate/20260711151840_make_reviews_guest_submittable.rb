class MakeReviewsGuestSubmittable < ActiveRecord::Migration[8.1]
  def up
    add_reference :reviews, :booking, null: true, foreign_key: true, index: { unique: true }
    add_column :reviews, :approved_at, :datetime

    # Existing reviews were entered by the admin — they were already public.
    execute "UPDATE reviews SET approved_at = created_at"
  end

  def down
    remove_reference :reviews, :booking
    remove_column :reviews, :approved_at
  end
end
