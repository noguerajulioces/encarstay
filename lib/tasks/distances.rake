# Distancias reales por calle desde cada propiedad a los puntos de referencia,
# calculadas con OSRM (el router público de OpenStreetMap) y guardadas en la
# fila. Correr de nuevo cada vez que cambien las coordenadas de una propiedad:
#
#   bin/rails distances:refresh
#
namespace :distances do
  USER_AGENT = "EncarStaysBot/1.0 (https://github.com/noguerajulioces/encarstay; contacto: alejandra.barreto.ab@gmail.com)".freeze

  # Acceso Pandolfo ("Marginal Sur") sobre la Ruta 6: el camino real de entrada
  # a estas propiedades no está mapeado en OSM, así que rutear desde ellas
  # inventa rodeos. Se rutea desde el cruce y se suma el tramo del acceso, que
  # pasa primero por el loft y sigue hasta la quinta y la cabaña.
  PANDOLFO = { latitude: -27.304955, longitude: -55.836847 }.freeze
  PANDOLFO_ORDER = %w[ loft-con-piscina-privada quinta-privada-con-entorno-natural cabana-amplia-con-piscina ].freeze

  desc "Recalcula las distancias por calle de cada propiedad (OSRM)"
  task refresh: :environment do
    require "net/http"

    route_km = ->(from_lat, from_lng, to_lat, to_lng) do
      url = URI("https://router.project-osrm.org/route/v1/driving/" \
                "#{from_lng},#{from_lat};#{to_lng},#{to_lat}?overview=false")
      response = Net::HTTP.get_response(url, { "User-Agent" => USER_AGENT })
      sleep 1 # cortesía con el servidor demo de OSRM

      unless response.is_a?(Net::HTTPSuccess)
        puts "OSRM HTTP #{response.code} — se mantiene el valor actual"
        next nil
      end

      meters = JSON.parse(response.body).dig("routes", 0, "distance")
      meters && meters / 1000.0
    end

    loft = Property.find_by(slug: PANDOLFO_ORDER.first)
    pandolfo_base = {} # landmark column => km del cruce al punto de referencia

    Property.where.not(latitude: nil).find_each do |property|
      updates = {}

      Property::LANDMARKS.each_value do |landmark|
        column = landmark.fetch(:column)

        km =
          if PANDOLFO_ORDER.include?(property.slug) && loft
            base = (pandolfo_base[column] ||= route_km.call(PANDOLFO[:latitude], PANDOLFO[:longitude],
                                                            landmark[:latitude], landmark[:longitude]))
            if base
              leg = loft.distance_km_to(PANDOLFO[:latitude], PANDOLFO[:longitude])
              leg += property.distance_km_to(loft.latitude, loft.longitude) unless property.slug == loft.slug
              base + leg
            end
          else
            route_km.call(property.latitude, property.longitude, landmark[:latitude], landmark[:longitude])
          end

        updates[column] = km.round(1) if km
      end

      property.update_columns(updates) if updates.any?
      puts "#{property.slug}: #{updates.map { |k, v| "#{k}=#{v}" }.join(", ")}"
    end
  end
end
