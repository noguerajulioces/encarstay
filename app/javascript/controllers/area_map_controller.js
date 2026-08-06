import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

// Mapa público de alojamientos: pines numerados (zona aproximada de cada
// propiedad) y puntos de referencia de la ciudad. Tiles de OpenStreetMap,
// sin API key — la misma base que el selector de ubicación del admin.
export default class extends Controller {
  static values = {
    stays: Array,      // [{ number, name, url, latitude, longitude }]
    references: Array, // [{ name, latitude, longitude }]
    paths: { type: Array, default: [] } // tramos de acceso: [[[lat, lng], …], …]
  }

  connect() {
    // Turbo puede restaurar el contenedor con tiles viejos dentro: se limpia
    // antes de inicializar para no apilar dos mapas.
    this.element.replaceChildren()

    // Sin zoom por scroll: la página scrollea por encima sin quedar atrapada.
    this.map = L.map(this.element, { scrollWheelZoom: false })
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap",
      maxZoom: 19
    }).addTo(this.map)
    L.control.scale({ imperial: false }).addTo(this.map)

    // Tramos de acceso (caminos que OSM no dibuja hasta el final): punteados
    // en el tono de los tracks de tierra del mapa base, debajo de los pines.
    this.pathsValue.forEach((points) => {
      L.polyline(points, { color: "#c98a3d", weight: 2.5, dashArray: "1 6", lineCap: "round", opacity: 0.95 }).addTo(this.map)
    })

    const bounds = []

    // Alojamientos que comparten zona (~100 m) se abren en abanico unos píxeles
    // vía el ancla del ícono — separación solo visual, la geografía no se toca.
    const groups = new Map()
    this.staysValue.forEach((stay) => {
      const key = `${stay.latitude.toFixed(3)},${stay.longitude.toFixed(3)}`
      if (!groups.has(key)) groups.set(key, [])
      groups.get(key).push(stay)
    })

    groups.forEach((group) => {
      group.forEach((stay, index) => {
        const shift = (index - (group.length - 1) / 2) * 24
        const icon = L.divIcon({
          className: "",
          html: `<div class="area-map-pin">${stay.number}</div>`,
          iconSize: [34, 34],
          iconAnchor: [17 + shift, 17]
        })
        const link = document.createElement("a")
        link.href = stay.url
        link.textContent = stay.name
        L.marker([stay.latitude, stay.longitude], { icon }).addTo(this.map).bindPopup(link)
        bounds.push([stay.latitude, stay.longitude])
      })
    })

    this.referencesValue.forEach((reference) => {
      const icon = L.divIcon({ className: "", html: '<div class="area-map-ref"></div>', iconSize: [12, 12], iconAnchor: [6, 6] })
      const label = document.createElement("span")
      label.textContent = reference.name
      L.marker([reference.latitude, reference.longitude], { icon, interactive: false })
        .addTo(this.map)
        .bindTooltip(label, { permanent: true, direction: "bottom", offset: [0, 6], className: "area-map-ref-tooltip" })
      bounds.push([reference.latitude, reference.longitude])
    })

    this.map.fitBounds(bounds, { padding: [45, 45] })

    // Leaflet calcula mal el tamaño si el contenedor aparece tarde (Turbo).
    setTimeout(() => this.map.invalidateSize(), 200)
  }

  disconnect() {
    if (this.map) this.map.remove()
  }
}
