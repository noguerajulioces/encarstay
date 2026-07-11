import { Controller } from "@hotwired/stimulus"

// Star picker for the public review form: paints stars up to the hovered or
// selected value. The underlying inputs are plain radios, so the form still
// works without JS.
export default class extends Controller {
  static targets = [ "star" ]

  connect() {
    this.paint(this.selected())
  }

  hover(event) {
    this.paint(Number(event.params.value))
  }

  leave() {
    this.paint(this.selected())
  }

  select() {
    this.paint(this.selected())
  }

  selected() {
    const checked = this.element.querySelector("input:checked")
    return checked ? Number(checked.value) : 0
  }

  paint(value) {
    this.starTargets.forEach((star, index) => {
      star.classList.toggle("text-sand-900", index < value)
      star.classList.toggle("text-sand-300", index >= value)
    })
  }
}
