import { Controller } from "@hotwired/stimulus"

// Airbnb-style horizontal card row: scroll by a page with the arrows, and hide
// each arrow when there's nothing more to scroll in that direction.
export default class extends Controller {
  static targets = ["track", "prev", "next"]

  connect() {
    this.onScroll = this.updateArrows.bind(this)
    this.trackTarget.addEventListener("scroll", this.onScroll, { passive: true })
    this.observer = new ResizeObserver(() => this.updateArrows())
    this.observer.observe(this.trackTarget)
    this.updateArrows()
  }

  disconnect() {
    this.trackTarget.removeEventListener("scroll", this.onScroll)
    this.observer?.disconnect()
  }

  prev() { this.page(-1) }
  next() { this.page(1) }

  page(direction) {
    this.trackTarget.scrollBy({ left: this.trackTarget.clientWidth * 0.9 * direction, behavior: "smooth" })
  }

  updateArrows() {
    const t = this.trackTarget
    const atStart = t.scrollLeft <= 2
    const atEnd = t.scrollLeft + t.clientWidth >= t.scrollWidth - 2
    if (this.hasPrevTarget) this.prevTarget.classList.toggle("invisible", atStart)
    if (this.hasNextTarget) this.nextTarget.classList.toggle("invisible", atEnd)
  }
}
