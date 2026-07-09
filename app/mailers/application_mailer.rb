class ApplicationMailer < ActionMailer::Base
  # Override the sender in production with a verified address on your domain by
  # setting the MAIL_FROM env var (e.g. "Encar Stays <hola@encarstays.com>").
  default from: ENV.fetch("MAIL_FROM", "Reservá Directo <reservas@example.com>")
  layout "mailer"
  helper ApplicationHelper
end
