import { Controller } from "@hotwired/stimulus"

// Client-side wishlist. The site has no public login, so favourites live in
// localStorage as a set of property slugs. The heart's visual state is driven
// entirely by its aria-pressed attribute (CSS does the fill).
const KEY = "encar:favorites"

export default class extends Controller {
  static values = { slug: String }

  connect() {
    this.render()
    this.onLoad = this.render.bind(this)
    document.addEventListener("turbo:load", this.onLoad)
  }

  disconnect() {
    document.removeEventListener("turbo:load", this.onLoad)
  }

  toggle(event) {
    // Never let the click fall through to the card's stretched link.
    event.preventDefault()
    event.stopPropagation()

    const set = this.read()
    set.has(this.slugValue) ? set.delete(this.slugValue) : set.add(this.slugValue)
    this.write(set)
    this.render()
  }

  render() {
    this.element.setAttribute("aria-pressed", this.read().has(this.slugValue) ? "true" : "false")
  }

  read() {
    try {
      return new Set(JSON.parse(localStorage.getItem(KEY)) || [])
    } catch {
      return new Set()
    }
  }

  write(set) {
    try {
      localStorage.setItem(KEY, JSON.stringify([...set]))
    } catch {
      // localStorage unavailable (private mode / quota) — favourites just won't persist.
    }
  }
}
