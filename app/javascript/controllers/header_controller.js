import { Controller } from "@hotwired/stimulus"

// Airbnb-style shrinking header: at the top the tabs show; once scrolled the
// tabs give way to a compact search pill. State is exposed as data-state on the
// header so Tailwind group-data variants can drive the cross-fade.
export default class extends Controller {
  connect() {
    this.onScroll = this.update.bind(this)
    window.addEventListener("scroll", this.onScroll, { passive: true })
    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
  }

  update() {
    this.element.dataset.state = window.scrollY > 20 ? "scrolled" : "top"
  }
}
