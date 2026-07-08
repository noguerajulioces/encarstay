import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

// Interactive map for placing a property's pin. Click the map (or drag the
// marker) and the latitude/longitude inputs update; typing into the inputs
// moves the marker back. Uses OpenStreetMap tiles — no API key needed.
export default class extends Controller {
  static targets = ["map", "latitude", "longitude"]
  static values = {
    center: { type: Array, default: [-27.3309, -55.8663] }, // Encarnación
    zoom: { type: Number, default: 13 }
  }

  connect() {
    const start = this.currentCoords() || this.centerValue

    this.map = L.map(this.mapTarget).setView(start, this.zoomValue)
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap",
      maxZoom: 19
    }).addTo(this.map)

    this.map.on("click", (event) => this.place(event.latlng))
    if (this.currentCoords()) this.place({ lat: start[0], lng: start[1] })

    // Leaflet miscalculates size when the container renders late (Turbo, tabs).
    setTimeout(() => this.map.invalidateSize(), 200)
  }

  disconnect() {
    if (this.map) this.map.remove()
  }

  // Move the pin from the latitude/longitude inputs (typed by hand).
  syncFromInputs() {
    const coords = this.currentCoords()
    if (!coords) return
    this.place({ lat: coords[0], lng: coords[1] })
    this.map.panTo(coords)
  }

  place({ lat, lng }) {
    if (this.marker) {
      this.marker.setLatLng([lat, lng])
    } else {
      this.marker = L.marker([lat, lng], { draggable: true, icon: this.pinIcon() }).addTo(this.map)
      this.marker.on("dragend", () => this.writeInputs(this.marker.getLatLng()))
    }
    this.writeInputs({ lat, lng })
  }

  writeInputs({ lat, lng }) {
    this.latitudeTarget.value = Number(lat).toFixed(6)
    this.longitudeTarget.value = Number(lng).toFixed(6)
  }

  currentCoords() {
    const lat = parseFloat(this.latitudeTarget.value)
    const lng = parseFloat(this.longitudeTarget.value)
    return Number.isFinite(lat) && Number.isFinite(lng) ? [lat, lng] : null
  }

  pinIcon() {
    return L.divIcon({
      className: "",
      iconSize: [24, 24],
      iconAnchor: [12, 24],
      html: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 0C6.48 0 2 4.48 2 10c0 6.5 10 14 10 14s10-7.5 10-14C22 4.48 17.52 0 12 0z" fill="#b45309"/>
        <circle cx="12" cy="10" r="4" fill="#fff"/>
      </svg>`
    })
  }
}
