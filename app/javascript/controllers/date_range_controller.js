import { Controller } from "@hotwired/stimulus"

// Turns the availability calendar into a range picker. Pick check-in and
// check-out by dragging from one day to another, tapping the two ends, or
// hovering to preview. The chosen dates are written into the booking form's
// fields and the form is submitted so the price updates.
//
// Two rules constrain a range, mirroring the server's booking validations:
//   * it can't cross an occupied night — the check-out clamps to that boundary;
//   * it must meet the minimum stay for its check-in date (raised by seasons),
//     so the check-out can never come closer than that many nights.
// When a check-in has fewer free nights ahead than its minimum, no range fits
// and the picker keeps waiting for a different check-in.
export default class extends Controller {
  static targets = ["day", "checkIn", "checkOut", "form", "controls", "summary", "submit"]
  static values = { occupied: Array, minNights: Number, minNightsOverrides: Object, locale: String, labels: Object }

  connect() {
    this.occupied = new Set(this.occupiedValue)
    this.pointerDown = false
    this.hoverDate = null
    this.endSelection = this.up.bind(this)
    window.addEventListener("pointerup", this.endSelection)
    window.addEventListener("pointercancel", this.endSelection)
    this.readInputs()
    this.render()
  }

  disconnect() {
    window.removeEventListener("pointerup", this.endSelection)
    window.removeEventListener("pointercancel", this.endSelection)
  }

  // --- day interactions ------------------------------------------------------

  down(event) {
    if (event.pointerType === "mouse") event.preventDefault() // no text selection while dragging
    const date = event.currentTarget.dataset.date
    this.pointerDown = true
    if (!this.start || this.end) {
      this.start = date // begin a fresh selection
      this.end = null
    } else {
      this.end = date // second endpoint (tap-tap)
    }
    this.hoverDate = date
    this.render()
  }

  enter(event) {
    const date = event.currentTarget.dataset.date
    this.hoverDate = date
    if (this.pointerDown && this.start) this.end = date // dragging
    if (this.start) this.render()
  }

  up() {
    if (!this.pointerDown) return
    this.pointerDown = false
    if (this.start && this.end) this.commit()
    else this.render()
  }

  clear() {
    this.start = null
    this.end = null
    this.hoverDate = null
    this.checkInTarget.value = ""
    this.checkOutTarget.value = ""
    this.render()
    this.formTarget.requestSubmit()
  }

  // A hand-typed date change: re-highlight the calendar and re-price.
  syncFromInputs() {
    this.readInputs()
    this.render()
    this.formTarget.requestSubmit()
  }

  // A guests change doesn't move the price, but it does feed the "Reservar" link,
  // so re-submit once a real range is set to keep that link current.
  refresh() {
    const checkIn = this.checkInTarget.value
    const checkOut = this.checkOutTarget.value
    if (checkIn && checkOut && checkOut > checkIn) this.formTarget.requestSubmit()
  }

  // --- internals -------------------------------------------------------------

  // Reflect the current form fields into the selection (on connect / manual edit).
  readInputs() {
    const checkIn = this.hasCheckInTarget ? this.checkInTarget.value : ""
    const checkOut = this.hasCheckOutTarget ? this.checkOutTarget.value : ""
    this.start = checkIn || null
    this.end = checkIn && checkOut && checkOut > checkIn ? checkOut : null
    this.hoverDate = null
  }

  // Finalize a range: order the ends, apply the stay rules, write the fields and
  // submit. If no valid range fits, keep waiting for the exit date.
  commit() {
    const [lo, wanted] = this.ordered(this.start, this.end)
    const { hi, valid } = this.effectiveRange(lo, wanted)
    if (!valid) {
      this.start = lo
      this.end = null
      this.hoverDate = lo
      this.render()
      return
    }
    this.start = lo
    this.end = hi
    this.hoverDate = null
    this.checkInTarget.value = lo
    this.checkOutTarget.value = hi
    this.render()
    this.formTarget.requestSubmit()
  }

  render() {
    let lo = this.start || null
    let hi = this.end || null
    if (lo && !hi && this.hoverDate) hi = this.hoverDate
    let range = null
    if (lo && hi) {
      ;[lo, hi] = this.ordered(lo, hi)
      range = this.effectiveRange(lo, hi)
      hi = range.hi
    }

    this.dayTargets.forEach((button) => {
      const date = button.dataset.date
      let state = "base"
      if (range && range.valid) {
        if (date === lo || date === hi) state = "endpoint"
        else if (date > lo && date < hi) state = "between"
      } else if (lo && date === lo) {
        state = "endpoint"
      }
      this.paint(button, state)
    })

    this.renderControls(lo, range)
    this.toggleSubmit()
  }

  // Hide "Ver precio" once the fields hold a valid range — the price is already
  // showing and refreshes on its own. Keep it as the prompt until then.
  toggleSubmit() {
    if (!this.hasSubmitTarget) return
    const checkIn = this.hasCheckInTarget ? this.checkInTarget.value : ""
    const checkOut = this.hasCheckOutTarget ? this.checkOutTarget.value : ""
    this.submitTarget.hidden = Boolean(checkIn && checkOut && checkOut > checkIn)
  }

  renderControls(lo, range) {
    if (this.hasControlsTarget) this.controlsTarget.hidden = !this.start
    if (!this.hasSummaryTarget) return
    const labels = this.labelsValue
    if (range && range.valid) {
      const nights = this.nightsBetween(lo, range.hi)
      const word = nights === 1 ? labels.nightWord : labels.nightsWord
      this.summaryTarget.textContent =
        `${nights} ${word} · ${this.format(lo)} → ${this.format(range.hi)}`
    } else if (range) {
      this.summaryTarget.textContent = this.fill(labels.noFreeNights, range.min)
    } else if (lo) {
      const min = this.minNightsFor(lo)
      this.summaryTarget.textContent = min > 1 ? this.fill(labels.chooseExitMin, min) : labels.chooseExit
    } else {
      this.summaryTarget.textContent = ""
    }
  }

  fill(template, count) {
    return (template || "").replace("%{count}", count)
  }

  paint(button, state) {
    button.classList.remove(
      "bg-emerald-50", "text-emerald-800", "hover:bg-emerald-100",
      "bg-emerald-100", "bg-emerald-700", "text-white"
    )
    if (state === "endpoint") button.classList.add("bg-emerald-700", "text-white")
    else if (state === "between") button.classList.add("bg-emerald-100", "text-emerald-800")
    else button.classList.add("bg-emerald-50", "text-emerald-800", "hover:bg-emerald-100")
  }

  // Resolve the check-out for a wanted range: no shorter than the minimum stay,
  // no later than the first occupied night. Invalid when those two collide —
  // the free gap after the check-in is shorter than the minimum stay.
  effectiveRange(lo, wanted) {
    const min = this.minNightsFor(lo)
    const floor = this.addDays(lo, min)
    const cap = this.firstOccupiedAfter(lo)
    let hi = wanted < floor ? floor : wanted
    if (cap && hi > cap) hi = cap
    const valid = hi > lo && hi >= floor && (!cap || floor <= cap)
    return { hi, valid, min }
  }

  minNightsFor(iso) {
    return Math.max(this.minNightsValue || 1, this.minNightsOverridesValue[iso] || 0, 1)
  }

  firstOccupiedAfter(iso) {
    let best = null
    this.occupied.forEach((date) => {
      if (date > iso && (best === null || date < best)) best = date
    })
    return best
  }

  ordered(a, b) {
    return a <= b ? [a, b] : [b, a]
  }

  // --- ISO date helpers (UTC to stay off DST edges) --------------------------

  toMillis(iso) {
    const [y, m, d] = iso.split("-").map(Number)
    return Date.UTC(y, m - 1, d)
  }

  addDays(iso, days) {
    return new Date(this.toMillis(iso) + days * 86400000).toISOString().slice(0, 10)
  }

  nightsBetween(lo, hi) {
    return Math.round((this.toMillis(hi) - this.toMillis(lo)) / 86400000)
  }

  // Locale-aware short date ("3 jul", "Jul 3", "3 de jul.") via the browser's
  // own formatter, so each language reads naturally.
  format(iso) {
    const [y, m, d] = iso.split("-").map(Number)
    return new Date(Date.UTC(y, m - 1, d)).toLocaleDateString(this.localeValue || "es", {
      day: "numeric", month: "short", timeZone: "UTC"
    })
  }
}
