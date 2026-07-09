# Idempotent seed data for development. Run with: bin/rails db:seed

admin = User.find_or_create_by!(email: "admin@reservas.test") do |user|
  user.name = "Administrador"
  user.password = "password"
end
puts "Admin: #{admin.email} / password"

# --- Amenities catalog (Airbnb-style services) ---
amenities_catalog = [
  { key: "wifi",             icon: "wifi",      position: 1 },
  { key: "kitchen",          icon: "kitchen",   position: 2 },
  { key: "air_conditioning", icon: "snowflake", position: 3 },
  { key: "pool",             icon: "pool",      position: 4 },
  { key: "free_parking",     icon: "car",       position: 5 },
  { key: "tv",               icon: "tv",        position: 6 },
  { key: "washer",           icon: "washer",    position: 7 },
  { key: "workspace",        icon: "workspace", position: 8 },
  { key: "pets_allowed",     icon: "paw",       position: 9 },
  { key: "security_cameras", icon: "shield",    position: 10 },
  { key: "smoke_alarm",      icon: "fire",      position: 11 },
  { key: "self_checkin",     icon: "key",       position: 12 }
]
amenities_catalog.each do |attrs|
  Amenity.find_or_create_by!(key: attrs[:key]) { |a| a.assign_attributes(attrs) }
end
puts "Servicios: #{Amenity.count}"

# Sample guest reviews reused across the seed properties (idempotent per property).
base_reviews = [
  { reviewer_name: "Ana",    reviewer_location: "Asunción, Paraguay",       stayed_on: Date.current - 40,  body: "Todo impecable y muy bien ubicado. Los anfitriones súper atentos." },
  { reviewer_name: "Bruno",  reviewer_location: "Posadas, Argentina",       stayed_on: Date.current - 70,  body: "Hermoso lugar, tal como en las fotos. Volveríamos sin dudar." },
  { reviewer_name: "Carla",  reviewer_location: "Encarnación, Paraguay",    stayed_on: Date.current - 95,  body: "Muy cómodo y limpio. La comunicación fue excelente en todo momento." },
  { reviewer_name: "Diego",  reviewer_location: "Ciudad del Este, Paraguay", stayed_on: Date.current - 120, body: "Excelente relación precio-calidad. Totalmente recomendado." },
  { reviewer_name: "Elena",  reviewer_location: "Buenos Aires, Argentina",  stayed_on: Date.current - 150, body: "Una estadía perfecta y el check-in fue rapidísimo." },
  { reviewer_name: "Fabián", reviewer_location: "Asunción, Paraguay",       stayed_on: Date.current - 180, body: "Nos encantó, ideal para descansar en familia." }
]

properties = [
  {
    name: "Casa del Lago",
    description: "Amplia casa con vista al lago, ideal para familias. Parrilla, jardín y muelle propio.\nA 5 minutos del centro de San Bernardino.",
    address_area: "San Bernardino",
    capacity: 6, bedrooms: 3, beds: 4, bathrooms: 2,
    latitude: -27.3240, longitude: -55.8770,
    base_price_cents: 45_000_000, currency: "PYG", cleaning_fee_cents: 8_000_000, min_nights: 2
  },
  {
    name: "Cabaña del Bosque",
    description: "Cabaña acogedora rodeada de naturaleza. Perfecta para desconectar en pareja.",
    address_area: "Areguá",
    capacity: 2, bedrooms: 1, beds: 1, bathrooms: 1,
    latitude: -27.3410, longitude: -55.8560,
    base_price_cents: 28_000_000, currency: "PYG", cleaning_fee_cents: 5_000_000, min_nights: 2
  },
  {
    name: "Loft Costanera",
    description: "Loft moderno frente a la costanera, con todas las comodidades y excelente ubicación.",
    address_area: "Encarnación",
    capacity: 4, bedrooms: 2, beds: 2, bathrooms: 1,
    latitude: -27.3320, longitude: -55.8685,
    base_price_cents: 38_000_000, currency: "PYG", cleaning_fee_cents: 6_000_000, min_nights: 2
  }
]

properties.each do |attributes|
  property = Property.find_or_create_by!(slug: attributes[:name].parameterize) do |record|
    record.assign_attributes(attributes)
  end

  # Keep the demo coordinates in sync so the search map is populated and spread.
  if attributes[:latitude].present?
    property.update_columns(latitude: attributes[:latitude], longitude: attributes[:longitude])
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

  amenity_keys = {
    "casa-del-lago"     => %w[wifi kitchen pool free_parking tv washer air_conditioning smoke_alarm self_checkin workspace pets_allowed],
    "cabana-del-bosque" => %w[wifi kitchen free_parking smoke_alarm self_checkin],
    "loft-costanera"    => %w[wifi kitchen air_conditioning tv washer workspace security_cameras smoke_alarm self_checkin]
  }.fetch(property.slug, %w[wifi kitchen tv air_conditioning])
  property.amenities = Amenity.where(key: amenity_keys)

  # Casa del Lago earns the "guest favourite" badge (all 5s); the rest average ~4.8.
  if property.reviews.none?
    ratings = property.slug == "casa-del-lago" ? [ 5, 5, 5, 5, 5, 5 ] : [ 5, 5, 5, 4, 5, 5 ]
    base_reviews.each_with_index do |attrs, i|
      property.reviews.create!(attrs.merge(rating: ratings[i]))
    end
  end

  puts "Propiedad: #{property.name} — #{property.amenities.count} servicios, #{property.reviews_count} reseñas (#{property.rating_cache} ★)"
end

# --- Guía de la ciudad: categorías + eventos y atracciones de Encarnación ---

categories = {
  "carnaval"          => { name_es: "Carnaval", name_en: "Carnival", name_pt: "Carnaval", icon: "ticket", position: 1 },
  "playas-costanera"  => { name_es: "Playas y costanera", name_en: "Beaches & riverfront", name_pt: "Praias e beira-rio", icon: "sparkles", position: 2 },
  "cultura-historia"  => { name_es: "Cultura e historia", name_en: "Culture & history", name_pt: "Cultura e história", icon: "compass", position: 3 },
  "gastronomia"       => { name_es: "Gastronomía", name_en: "Food & drink", name_pt: "Gastronomia", icon: "star", position: 4 },
  "ferias-eventos"    => { name_es: "Ferias y eventos", name_en: "Fairs & events", name_pt: "Feiras e eventos", icon: "calendar", position: 5 }
}

cats = categories.to_h do |slug, attrs|
  [ slug, Category.find_or_create_by!(slug: slug) { |c| c.assign_attributes(attrs) } ]
end

carnival_year = Date.current.month <= 2 ? Date.current.year : Date.current.year + 1

guide_entries = [
  {
    slug: "carnaval-encarnaceno", kind: "event", category: "carnaval", featured: true, published: true,
    title_es: "Carnaval Encarnaceno", title_en: "Encarnación Carnival", title_pt: "Carnaval de Encarnación",
    summary_es: "El carnaval más grande del Paraguay, en el Sambódromo sobre la costanera.",
    summary_en: "Paraguay's biggest carnival, at the Sambadrome on the riverfront.",
    summary_pt: "O maior carnaval do Paraguai, no Sambódromo na beira-rio.",
    description_es: "Cada fin de semana de verano, Encarnación se convierte en la capital del carnaval paraguayo. Comparsas, plumas, batucada y miles de visitantes llenan el Sambódromo. Conviene reservar alojamiento con anticipación.",
    description_en: "Every summer weekend, Encarnación becomes the capital of Paraguayan carnival. Troupes, feathers, batucada and thousands of visitors fill the Sambadrome. Book your stay early.",
    address: "Sambódromo de Encarnación", area: "Costanera",
    latitude: -27.3300, longitude: -55.8650,
    starts_at: Time.zone.local(carnival_year, 1, 24, 21), ends_at: Time.zone.local(carnival_year, 2, 22, 23),
    schedule_note_es: "Fines de semana de enero y febrero"
  },
  {
    slug: "expo-itapua", kind: "event", category: "ferias-eventos", featured: false, published: true,
    title_es: "Expo Itapúa", title_en: "Expo Itapúa", title_pt: "Expo Itapúa",
    summary_es: "Feria agropecuaria, comercial e industrial de la región.",
    summary_en: "Regional agricultural, trade and industrial fair.",
    description_es: "Una de las ferias más importantes del sur del país, con stands, maquinaria, gastronomía y espectáculos.",
    area: "Capitán Miranda",
    starts_at: Time.zone.local(carnival_year, 5, 10, 9), ends_at: Time.zone.local(carnival_year, 5, 19, 22)
  },
  {
    slug: "costanera-de-encarnacion", kind: "attraction", category: "playas-costanera", featured: true, published: true,
    title_es: "Costanera de Encarnación", title_en: "Encarnación Riverfront", title_pt: "Beira-rio de Encarnación",
    summary_es: "Paseo frente al río Paraná con playas urbanas, bares y atardeceres.",
    summary_en: "Paraná river promenade with urban beaches, bars and sunsets.",
    description_es: "El corazón al aire libre de la ciudad: kilómetros de paseo, ciclovía, playas de arena y una vida nocturna que crece en verano.",
    address: "Av. Costanera", area: "Costanera",
    latitude: -27.3360, longitude: -55.8720
  },
  {
    slug: "playa-san-jose", kind: "attraction", category: "playas-costanera", featured: true, published: true,
    title_es: "Playa San José", title_en: "San José Beach", title_pt: "Praia San José",
    summary_es: "La playa urbana más popular, ideal para el verano en familia.",
    summary_en: "The most popular urban beach, great for summer with family.",
    description_es: "Arena, sombrillas y aguas del Paraná a pasos del centro. En temporada alta concentra deportes de playa y food trucks.",
    area: "Costanera", latitude: -27.3339, longitude: -55.8695
  },
  {
    slug: "ruinas-jesuiticas-trinidad", kind: "attraction", category: "cultura-historia", featured: true, published: true,
    title_es: "Ruinas Jesuíticas de Trinidad", title_en: "Jesuit Ruins of Trinidad", title_pt: "Ruínas Jesuíticas de Trinidad",
    summary_es: "Patrimonio de la Humanidad de la UNESCO, a 30 minutos de la ciudad.",
    summary_en: "UNESCO World Heritage Site, 30 minutes from the city.",
    description_es: "La Santísima Trinidad del Paraná es la reducción jesuítica mejor conservada del país. Imperdible el show nocturno de luces y sonido.",
    address: "Trinidad, Itapúa", area: "Trinidad",
    latitude: -27.1300, longitude: -55.7200, external_url: "https://whc.unesco.org/en/list/648/"
  },
  {
    slug: "cervecerias-de-encarnacion", kind: "attraction", category: "gastronomia", featured: false, published: true,
    title_es: "Cervecerías de Encarnación", title_en: "Encarnación breweries", title_pt: "Cervejarias de Encarnación",
    summary_es: "Circuito de cervezas artesanales y gastronomía sobre la costanera.",
    summary_en: "Craft-beer and food circuit along the riverfront.",
    description_es: "Encarnación tiene una escena cervecera en auge. Bares y patios gastronómicos concentran la salida nocturna, sobre todo en verano.",
    area: "Centro"
  }
]

guide_entries.each do |attrs|
  category = cats.fetch(attrs.delete(:category))
  GuideEntry.find_or_create_by!(slug: attrs[:slug]) { |g| g.assign_attributes(attrs.merge(category: category)) }
end

puts "Guía: #{Category.count} categorías, #{GuideEntry.events.count} eventos, #{GuideEntry.attractions.count} lugares"
