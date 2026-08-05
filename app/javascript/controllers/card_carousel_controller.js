import { Controller } from "@hotwired/stimulus"

// The little image slider inside a listing card: swipe/scroll photos, arrows on
// hover, dots at the bottom. Arrows swallow the click so they never trigger the
// card's link, and the slider loops so an arrow never disappears under the
// user's cursor (a click on a vanished arrow would fall through to the link).
export default class extends Controller {
  static targets = ["track", "dot", "prev", "next", "image"]

  connect() {
    this.onScroll = this.update.bind(this)
    this.onPointerDown = this.prepare.bind(this)
    this.trackTarget.addEventListener("scroll", this.onScroll, { passive: true })
    this.trackTarget.addEventListener("pointerdown", this.onPointerDown, { passive: true })
    this.update()
  }

  disconnect() {
    this.trackTarget.removeEventListener("scroll", this.onScroll)
    this.trackTarget.removeEventListener("pointerdown", this.onPointerDown)
  }

  go(event) {
    event.preventDefault()
    event.stopPropagation()
    const target = (this.index + event.params.dir + this.count) % this.count
    this.#load(target)
    this.trackTarget.scrollTo({ left: target * this.trackTarget.clientWidth, behavior: "smooth" })
  }

  prepare() {
    this.#load((this.index - 1 + this.count) % this.count)
    this.#load((this.index + 1) % this.count)
  }

  get index() {
    return Math.round(this.trackTarget.scrollLeft / this.trackTarget.clientWidth)
  }

  get count() {
    return this.dotTargets.length
  }

  update() {
    const i = this.index
    this.#load(i)
    this.dotTargets.forEach((dot, n) => {
      dot.classList.toggle("opacity-100", n === i)
      dot.classList.toggle("opacity-50", n !== i)
    })
  }

  #load(index) {
    const image = this.imageTargets[index]
    if (!image || image.hasAttribute("src")) return

    image.src = image.dataset.cardCarouselSrcValue
    delete image.dataset.cardCarouselSrcValue
  }
}
