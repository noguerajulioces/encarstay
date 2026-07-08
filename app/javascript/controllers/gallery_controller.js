import { Controller } from "@hotwired/stimulus"

// Airbnb-style photo viewer. The hero mosaic and the "show all photos" button
// open a full-screen lightbox that steps through every photo with the arrows,
// the keyboard, or a swipe. Large images load lazily — only the photo on screen
// is fetched, so opening the viewer never pulls the whole set at once.
export default class extends Controller {
  static targets = ["lightbox", "image", "counter"]
  static values = { urls: Array }

  connect() {
    this.index = 0
    this.onKey = this.key.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this.onKey)
    document.body.style.overflow = ""
  }

  open(event) {
    event.preventDefault()
    this.index = Number(event.currentTarget.dataset.index || 0)
    this.render()
    this.lightboxTarget.hidden = false
    document.body.style.overflow = "hidden" // lock scroll behind the overlay
    document.addEventListener("keydown", this.onKey)
  }

  close() {
    this.lightboxTarget.hidden = true
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.onKey)
  }

  next(event) {
    if (event) event.stopPropagation()
    this.index = (this.index + 1) % this.urlsValue.length
    this.render()
  }

  prev(event) {
    if (event) event.stopPropagation()
    this.index = (this.index - 1 + this.urlsValue.length) % this.urlsValue.length
    this.render()
  }

  // Close only when the tap lands on the backdrop itself, not on the photo.
  backdrop(event) {
    if (event.target === event.currentTarget) this.close()
  }

  render() {
    this.imageTarget.src = this.urlsValue[this.index]
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.index + 1} / ${this.urlsValue.length}`
    }
  }

  key(event) {
    if (event.key === "Escape") this.close()
    else if (event.key === "ArrowRight") this.next()
    else if (event.key === "ArrowLeft") this.prev()
  }
}
