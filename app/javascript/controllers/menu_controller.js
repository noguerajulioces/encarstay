import { Controller } from "@hotwired/stimulus"

// Small dropdown (the Airbnb user menu). Toggles a panel, closes on outside
// click or Escape.
export default class extends Controller {
  static targets = ["panel", "button"]

  connect() {
    this.onDocClick = this.closeOnOutside.bind(this)
    this.onKey = this.closeOnEscape.bind(this)
    document.addEventListener("click", this.onDocClick)
    document.addEventListener("keydown", this.onKey)
  }

  disconnect() {
    document.removeEventListener("click", this.onDocClick)
    document.removeEventListener("keydown", this.onKey)
  }

  toggle(event) {
    event.stopPropagation()
    this.panelTarget.hidden = !this.panelTarget.hidden
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-expanded", String(!this.panelTarget.hidden))
  }

  closeOnOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  close() {
    if (this.hasPanelTarget) this.panelTarget.hidden = true
    if (this.hasButtonTarget) this.buttonTarget.setAttribute("aria-expanded", "false")
  }
}
