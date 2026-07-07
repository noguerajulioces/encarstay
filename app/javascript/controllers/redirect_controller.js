import { Controller } from "@hotwired/stimulus"

// Sends the form to a path built from an input value, e.g. /bookings/:code.
// data-redirect-template-value holds the URL template with a ":code" placeholder.
export default class extends Controller {
  static targets = ["input"]
  static values = { template: String }

  go(event) {
    event.preventDefault()
    const value = this.inputTarget.value.trim().toUpperCase()
    if (value) window.location.assign(this.templateValue.replace(":code", encodeURIComponent(value)))
  }
}
