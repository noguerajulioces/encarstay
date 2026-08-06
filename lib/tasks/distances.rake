# Distancias reales por calle desde cada propiedad a los puntos de referencia,
# calculadas con OSRM (el router público de OpenStreetMap) y guardadas en la
# fila. Correr de nuevo cada vez que cambien las coordenadas de una propiedad:
#
#   bin/rails distances:refresh
#
namespace :distances do
  USER_AGENT = "EncarStaysBot/1.0 (https://github.com/noguerajulioces/encarstay; contacto: alejandra.barreto.ab@gmail.com)".freeze

  desc "Recalcula las distancias por calle de cada propiedad (OSRM)"
  task refresh: :environment do
    require "net/http"

    Property.where.not(latitude: nil).find_each do |property|
      updates = {}

      # Referencias compartidas con el mapa público (Property::LANDMARKS).
      Property::LANDMARKS.each_value do |landmark|
        column = landmark.fetch(:column)
        url = URI("https://router.project-osrm.org/route/v1/driving/" \
                  "#{property.longitude},#{property.latitude};#{landmark[:longitude]},#{landmark[:latitude]}?overview=false")
        response = Net::HTTP.get_response(url, { "User-Agent" => USER_AGENT })

        unless response.is_a?(Net::HTTPSuccess)
          puts "#{property.slug} #{column}: HTTP #{response.code} — se mantiene el valor actual"
          next
        end

        meters = JSON.parse(response.body).dig("routes", 0, "distance")
        updates[column] = (meters / 1000.0).round(1) if meters

        sleep 1 # cortesía con el servidor demo de OSRM
      end

      property.update_columns(updates) if updates.any?
      puts "#{property.slug}: #{updates.map { |k, v| "#{k}=#{v}" }.join(", ")}"
    end
  end
end
