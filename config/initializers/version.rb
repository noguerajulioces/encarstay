# Single-source application version. Read from the root VERSION file so the
# changelog, git tags and the running app never drift apart.
module Reservas
  VERSION = File.read(Rails.root.join("VERSION")).strip.freeze
end
