import { Controller } from "@hotwired/stimulus"

// Floating flash toast: slides in, auto-dismisses after a delay, and can be
// closed by hand. Removes itself from the DOM once it has faded out.
export default class extends Controller {
  static values = { delay: { type: Number, default: 6000 } }

  connect() {
    requestAnimationFrame(() => this.element.classList.remove("opacity-0", "translate-y-2"))
    if (this.delayValue > 0) this.timer = setTimeout(() => this.close(), this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  close() {
    clearTimeout(this.timer)
    this.element.classList.add("opacity-0", "translate-y-2")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}
