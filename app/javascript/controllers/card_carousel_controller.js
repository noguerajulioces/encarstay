import { Controller } from "@hotwired/stimulus"

// The little image slider inside a listing card: swipe/scroll photos, arrows on
// hover, dots at the bottom. Arrows swallow the click so they never trigger the
// card's link.
export default class extends Controller {
  static targets = ["track", "dot", "prev", "next"]

  connect() {
    this.onScroll = this.update.bind(this)
    this.trackTarget.addEventListener("scroll", this.onScroll, { passive: true })
    this.update()
  }

  disconnect() {
    this.trackTarget.removeEventListener("scroll", this.onScroll)
  }

  go(event) {
    event.preventDefault()
    event.stopPropagation()
    const target = Math.min(Math.max(this.index + event.params.dir, 0), this.count - 1)
    this.trackTarget.scrollTo({ left: target * this.trackTarget.clientWidth, behavior: "smooth" })
  }

  get index() {
    return Math.round(this.trackTarget.scrollLeft / this.trackTarget.clientWidth)
  }

  get count() {
    return this.dotTargets.length
  }

  update() {
    const i = this.index
    this.dotTargets.forEach((dot, n) => {
      dot.classList.toggle("opacity-100", n === i)
      dot.classList.toggle("opacity-50", n !== i)
    })
    if (this.hasPrevTarget) this.prevTarget.classList.toggle("invisible", i <= 0)
    if (this.hasNextTarget) this.nextTarget.classList.toggle("invisible", i >= this.count - 1)
  }
}
