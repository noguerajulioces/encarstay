import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

// Read-only, multi-marker map for the search page. Plots stays and points of
// interest (attractions + events) in toggleable layers, with POI category
// filtering. Reuses the same OpenStreetMap tiles as the admin map-picker — no
// API key, no cost.
export default class extends Controller {
  static targets = ["map"]
  static values = {
    properties: { type: Array, default: [] },
    attractions: { type: Array, default: [] },
    events: { type: Array, default: [] },
    center: { type: Array, default: [-27.3309, -55.8663] }, // Encarnación
    zoom: { type: Number, default: 13 }
  }

  static COLORS = { properties: "#74593d", attractions: "#0f766e", events: "#b91c1c" }

  connect() {
    // Scroll-wheel zoom off so the map doesn't hijack page scrolling; the +/-
    // control and pinch-zoom still work.
    this.map = L.map(this.mapTarget, { scrollWheelZoom: false }).setView(this.centerValue, this.zoomValue)
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap",
      maxZoom: 19
    }).addTo(this.map)

    this.groups = {
      properties: L.layerGroup().addTo(this.map),
      attractions: L.layerGroup().addTo(this.map),
      events: L.layerGroup().addTo(this.map)
    }
    this.poiMarkers = [] // { marker, layer, category } for category filtering

    this.addMarkers(this.propertiesValue, "properties")
    this.addMarkers(this.attractionsValue, "attractions")
    this.addMarkers(this.eventsValue, "events")

    this.fitToMarkers()
    // Leaflet miscalculates size when the container renders late (Turbo, sticky).
    setTimeout(() => this.map.invalidateSize(), 200)
  }

  disconnect() {
    if (this.map) this.map.remove()
  }

  addMarkers(items, layer) {
    items.forEach((item) => {
      if (!Number.isFinite(item.lat) || !Number.isFinite(item.lng)) return
      const marker = L.marker([item.lat, item.lng], { icon: this.pinIcon(this.constructor.COLORS[layer]) })
      marker.bindPopup(this.popupHtml(item))
      marker.addTo(this.groups[layer])
      if (layer !== "properties") {
        this.poiMarkers.push({ marker, layer, category: item.category_slug || "" })
      }
    })
  }

  // Show/hide a whole layer from its checkbox.
  toggleLayer(event) {
    const group = this.groups[event.target.dataset.layer]
    if (!group) return
    if (event.target.checked) {
      group.addTo(this.map)
    } else {
      this.map.removeLayer(group)
    }
  }

  // Filter POI markers by category slug ("" = show all).
  filterCategory(event) {
    const slug = event.currentTarget.dataset.category || ""
    this.element.querySelectorAll("[data-category]").forEach((chip) => {
      chip.setAttribute("aria-pressed", chip.dataset.category === slug ? "true" : "false")
    })
    this.poiMarkers.forEach(({ marker, layer, category }) => {
      const group = this.groups[layer]
      if (slug === "" || category === slug) {
        marker.addTo(group)
      } else {
        group.removeLayer(marker)
      }
    })
  }

  fitToMarkers() {
    const coords = [...this.propertiesValue, ...this.attractionsValue, ...this.eventsValue]
      .filter((i) => Number.isFinite(i.lat) && Number.isFinite(i.lng))
      .map((i) => [i.lat, i.lng])
    if (coords.length > 0) {
      this.map.fitBounds(coords, { padding: [40, 40], maxZoom: 15 })
    }
  }

  popupHtml(item) {
    const title = item.name || item.title || ""
    const meta = item.price || item.category_name || item.area || ""
    const thumb = item.thumb
      ? `<img src="${item.thumb}" alt="" style="width:100%;height:90px;object-fit:cover;border-radius:8px;margin-bottom:6px" />`
      : ""
    const metaHtml = meta ? `<div style="color:#746c5e;font-size:12px;margin-top:2px">${this.escape(meta)}</div>` : ""
    return `<div style="width:180px">${thumb}` +
      `<a href="${item.url}" style="font-weight:600;color:#5e4832;text-decoration:none">${this.escape(title)}</a>` +
      `${metaHtml}</div>`
  }

  escape(text) {
    const div = document.createElement("div")
    div.textContent = text == null ? "" : text
    return div.innerHTML
  }

  pinIcon(color) {
    return L.divIcon({
      className: "",
      iconSize: [24, 24],
      iconAnchor: [12, 24],
      html: `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 0C6.48 0 2 4.48 2 10c0 6.5 10 14 10 14s10-7.5 10-14C22 4.48 17.52 0 12 0z" fill="${color}"/>
        <circle cx="12" cy="10" r="4" fill="#fff"/>
      </svg>`
    })
  }
}
