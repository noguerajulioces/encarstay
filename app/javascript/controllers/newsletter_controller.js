import { Controller } from "@hotwired/stimulus"

// Site-wide email-capture popup. Opens once per visitor — on exit-intent
// (desktop) or ~50% scroll depth (mobile), after a short minimum delay — then
// remembers the choice in localStorage so it never nags again. Escape/backdrop
// close and body scroll-lock mirror the gallery lightbox.
export default class extends Controller {
  static values = {
    storageKey: { type: String, default: "newsletter" },
    delay: { type: Number, default: 8000 },
    scroll: { type: Number, default: 0.5 }
  }

  connect() {
    if (localStorage.getItem(this.storageKeyValue)) return // dismissed or subscribed already

    this.armed = false
    this.onExit = this.exitIntent.bind(this)
    this.onScroll = this.scrollDepth.bind(this)
    this.onKey = this.key.bind(this)

    this.armTimer = setTimeout(() => { this.armed = true }, this.delayValue)
    document.addEventListener("mouseout", this.onExit)
    window.addEventListener("scroll", this.onScroll, { passive: true })
  }

  disconnect() {
    this.teardownTriggers()
    document.removeEventListener("keydown", this.onKey)
    document.body.style.overflow = ""
  }

  // Desktop: the cursor leaving through the top of the viewport signals intent
  // to leave. relatedTarget is null when the pointer exits the window.
  exitIntent(event) {
    if (this.armed && event.clientY <= 0 && !event.relatedTarget) this.open()
  }

  // Mobile (and desktop) fallback: halfway down the page.
  scrollDepth() {
    const scrollable = document.documentElement.scrollHeight - window.innerHeight
    if (this.armed && scrollable > 0 && window.scrollY / scrollable >= this.scrollValue) this.open()
  }

  open() {
    this.teardownTriggers()
    this.element.hidden = false
    document.body.style.overflow = "hidden" // lock scroll behind the overlay
    document.addEventListener("keydown", this.onKey)
  }

  // Manual dismiss (X or backdrop) — remember it so we don't ask again.
  close() {
    this.hide()
    this.remember("dismissed")
  }

  backdrop(event) {
    if (event.target === event.currentTarget) this.close()
  }

  // Fired via turbo:submit-end on the popup form after a successful signup.
  subscribed(event) {
    if (!event.detail?.success) return
    this.remember("subscribed")
    setTimeout(() => this.hide(), 2500)
  }

  key(event) {
    if (event.key === "Escape") this.close()
  }

  hide() {
    this.element.hidden = true
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.onKey)
  }

  remember(value) {
    try { localStorage.setItem(this.storageKeyValue, value) } catch (_) { /* private mode */ }
  }

  teardownTriggers() {
    clearTimeout(this.armTimer)
    document.removeEventListener("mouseout", this.onExit)
    window.removeEventListener("scroll", this.onScroll)
  }
}
