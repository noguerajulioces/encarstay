require "net/http"

# First-party proxy for the self-hosted Plausible tracker (see docs/PLAUSIBLE.md).
# Serving the script and the event endpoint from our own domain keeps the
# dashboard private on the analytics server and slips past adblockers.
class PlausibleProxyController < ActionController::Base
  # The tracker posts events without a CSRF token; the payload is opaque JSON
  # relayed upstream, so there is nothing to forge here.
  skip_forgery_protection

  SCRIPTS = %w[ script.js script.outbound-links.js ].freeze

  def script
    return head :not_found unless backend && SCRIPTS.include?(params[:script])

    upstream = backend_get("/js/#{params[:script]}")
    expires_in 12.hours, public: true
    send_data upstream.body, type: "application/javascript", disposition: "inline"
  rescue *CONNECTION_ERRORS
    head :bad_gateway
  end

  def event
    return head :not_found unless backend

    upstream = backend_post("/api/event", request.raw_post)
    head upstream.code.to_i
  rescue *CONNECTION_ERRORS
    head :bad_gateway
  end

  private
    CONNECTION_ERRORS = [ SocketError, Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Net::ProtocolError ].freeze

    def backend
      ENV["PLAUSIBLE_BACKEND_URL"].presence
    end

    def backend_get(path)
      http_client.get(path)
    end

    # Plausible reads the visitor's IP and user agent to count unique visits,
    # so both travel along with the event payload.
    def backend_post(path, body)
      http_client.post(path, body,
        "Content-Type" => "application/json",
        "User-Agent" => request.user_agent.to_s,
        "X-Forwarded-For" => request.remote_ip)
    end

    def http_client
      uri = URI(backend)
      Net::HTTP.new(uri.host, uri.port).tap do |http|
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 2
        http.read_timeout = 5
      end
    end
end
