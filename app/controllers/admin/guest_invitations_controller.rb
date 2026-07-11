class Admin::GuestInvitationsController < Admin::BaseController
  # Fire the one-time re-engagement invite to every past guest not yet on the list.
  def create
    count = Subscriber.invite_past_guests!
    redirect_to admin_subscribers_path, notice: "Se enviaron #{count} invitaciones a huéspedes anteriores."
  end
end
