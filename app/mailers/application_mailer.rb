class ApplicationMailer < ActionMailer::Base
  default from: "Reservá Directo <reservas@example.com>"
  layout "mailer"
  helper ApplicationHelper
end
