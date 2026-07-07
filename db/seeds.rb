# Idempotent seed data for development. Run with: bin/rails db:seed

admin = User.find_or_create_by!(email: "admin@reservas.test") do |user|
  user.name = "Administrador"
  user.password = "password"
end
puts "Admin: #{admin.email} / password"

properties = [
  {
    name: "Casa del Lago",
    description: "Amplia casa con vista al lago, ideal para familias. Parrilla, jardín y muelle propio.\nA 5 minutos del centro de San Bernardino.",
    address_area: "San Bernardino",
    capacity: 6, bedrooms: 3, beds: 4, bathrooms: 2,
    base_price_cents: 45_000_000, currency: "PYG", cleaning_fee_cents: 8_000_000, min_nights: 2
  },
  {
    name: "Cabaña del Bosque",
    description: "Cabaña acogedora rodeada de naturaleza. Perfecta para desconectar en pareja.",
    address_area: "Areguá",
    capacity: 2, bedrooms: 1, beds: 1, bathrooms: 1,
    base_price_cents: 28_000_000, currency: "PYG", cleaning_fee_cents: 5_000_000, min_nights: 2
  },
  {
    name: "Loft Costanera",
    description: "Loft moderno frente a la costanera, con todas las comodidades y excelente ubicación.",
    address_area: "Encarnación",
    capacity: 4, bedrooms: 2, beds: 2, bathrooms: 1,
    base_price_cents: 38_000_000, currency: "PYG", cleaning_fee_cents: 6_000_000, min_nights: 2
  }
]

properties.each do |attributes|
  property = Property.find_or_create_by!(slug: attributes[:name].parameterize) do |record|
    record.assign_attributes(attributes)
  end

  property.seasonal_rates.find_or_create_by!(name: "Temporada alta") do |rate|
    rate.starts_on = Date.new(Date.current.year, 12, 15)
    rate.ends_on   = Date.new(Date.current.year + 1, 2, 28)
    rate.price_per_night_cents = (property.base_price_cents * 1.4).to_i
    rate.min_nights = 3
  end

  property.calendar_sources.find_or_create_by!(name: "Airbnb") do |source|
    source.ical_url = "https://www.airbnb.com/calendar/ical/#{property.slug}.ics"
  end

  puts "Propiedad: #{property.name} — feed iCal: /calendars/#{property.calendar_token}/#{property.slug}.ics"
end
