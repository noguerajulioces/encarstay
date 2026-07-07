import { Controller } from "@hotwired/stimulus"

// Copies the value of the source target to the clipboard.
export default class extends Controller {
  static targets = ["source"]

  copy(event) {
    event.preventDefault()
    this.sourceTarget.select()
    navigator.clipboard.writeText(this.sourceTarget.value)
    const button = event.currentTarget
    const label = button.textContent
    button.textContent = "¡Copiado!"
    setTimeout(() => (button.textContent = label), 1500)
  }
}
