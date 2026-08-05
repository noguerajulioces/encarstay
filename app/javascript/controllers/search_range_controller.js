import { Controller } from "@hotwired/stimulus"

// A single date-range field for the availability search bar. Clicking the field
// opens a month calendar: the first tap sets check-in, the second sets check-out
// and fills both hidden inputs at once, then the panel closes. No second field
// to fill by hand — one control completes the whole range.
export default class extends Controller {
  static targets = ["display", "checkIn", "checkOut", "panel", "calendar", "clear"]
  static values = { locale: String, labels: Object, minNights: { type: Number, default: 1 } }

  connect() {
    this.checkIn = this.checkInTarget.value || null
    this.checkOut = this.checkOutTarget.value || null
    this.hoverDate = null
    const base = this.checkIn ? this.parse(this.checkIn) : new Date()
    this.viewYear = base.getFullYear()
    this.viewMonth = base.getMonth()

    this.closeOnOutside = this.maybeClose.bind(this)
    document.addEventListener("click", this.closeOnOutside)

    this.renderDisplay()
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutside)
  }

  // --- open / close ----------------------------------------------------------

  open(event) {
    event.preventDefault()
    this.panelTarget.hidden = false
    this.renderCalendar()
  }

  close() {
    this.panelTarget.hidden = true
    this.hoverDate = null
  }

  maybeClose(event) {
    if (this.panelTarget.hidden) return
    if (this.element.contains(event.target)) return
    // A day/month tap re-renders the calendar, detaching the very node that was
    // clicked; that click still bubbles here, but its target is no longer in the
    // DOM. Treat a detached target as an internal click, not an outside one.
    if (!event.target.isConnected) return
    this.close()
  }

  // --- selection -------------------------------------------------------------

  pick(event) {
    const date = event.currentTarget.dataset.date
    if (!this.checkIn || this.checkOut || date <= this.checkIn) {
      this.checkIn = date // start a fresh range
      this.checkOut = null
    } else if (date < this.minCheckout()) {
      return // shorter than the minimum stay — the day is painted as blocked
    } else {
      this.checkOut = date // second endpoint completes the range
    }
    this.writeInputs()
    this.renderDisplay()
    this.paintDays()
    if (this.checkIn && this.checkOut) this.close()
  }

  hover(event) {
    if (this.checkIn && !this.checkOut) {
      this.hoverDate = event.currentTarget.dataset.date
      this.paintDays()
    }
  }

  clear(event) {
    event.preventDefault()
    this.checkIn = null
    this.checkOut = null
    this.hoverDate = null
    this.writeInputs()
    this.renderDisplay()
    this.renderCalendar()
  }

  prevMonth(event) {
    event.preventDefault()
    this.shiftMonth(-1)
  }

  nextMonth(event) {
    event.preventDefault()
    this.shiftMonth(1)
  }

  shiftMonth(delta) {
    const d = new Date(this.viewYear, this.viewMonth + delta, 1)
    this.viewYear = d.getFullYear()
    this.viewMonth = d.getMonth()
    this.renderCalendar()
  }

  // --- internals -------------------------------------------------------------

  writeInputs() {
    this.checkInTarget.value = this.checkIn || ""
    this.checkOutTarget.value = this.checkOut || ""
    if (this.hasClearTarget) this.clearTarget.hidden = !this.checkIn
  }

  renderDisplay() {
    const labels = this.labelsValue
    if (this.checkIn && this.checkOut) {
      this.displayTarget.textContent = `${this.format(this.checkIn)} → ${this.format(this.checkOut)}`
    } else if (this.checkIn) {
      this.displayTarget.textContent = `${this.format(this.checkIn)} → …`
    } else {
      this.displayTarget.textContent = labels.placeholder
    }
    if (this.hasClearTarget) this.clearTarget.hidden = !this.checkIn
  }

  renderCalendar() {
    const labels = this.labelsValue
    const first = new Date(this.viewYear, this.viewMonth, 1)
    const daysInMonth = new Date(this.viewYear, this.viewMonth + 1, 0).getDate()
    const offset = (first.getDay() + 6) % 7 // Monday-first
    const today = this.iso(new Date())
    const canGoBack = `${this.viewYear}-${String(this.viewMonth + 1).padStart(2, "0")}` >
      today.slice(0, 7)

    const weekdays = labels.weekdays
      .map((w) => `<div class="py-1 text-center text-[0.65rem] font-semibold uppercase text-sand-400">${w}</div>`)
      .join("")

    let cells = ""
    for (let i = 0; i < offset; i++) cells += "<div></div>"
    for (let day = 1; day <= daysInMonth; day++) {
      const iso = `${this.viewYear}-${String(this.viewMonth + 1).padStart(2, "0")}-${String(day).padStart(2, "0")}`
      cells += this.dayCell(iso, day, iso < today)
    }

    this.calendarTarget.innerHTML = `
      <div class="mb-2 flex items-center justify-between">
        <button type="button" data-action="search-range#prevMonth" ${canGoBack ? "" : "disabled"}
          class="rounded-lg p-1.5 text-sand-500 hover:bg-sand-100 disabled:opacity-30 disabled:hover:bg-transparent">&larr;</button>
        <span class="text-sm font-semibold capitalize text-sand-800">${this.monthLabel()}</span>
        <button type="button" data-action="search-range#nextMonth"
          class="rounded-lg p-1.5 text-sand-500 hover:bg-sand-100">&rarr;</button>
      </div>
      <div class="grid grid-cols-7">${weekdays}</div>
      <div class="grid grid-cols-7 gap-y-1">${cells}</div>
    `
    this.paintDays()
  }

  // Day buttons are built once per month; selecting or hovering only repaints
  // their state classes, so the DOM never churns on mouse move.
  dayCell(iso, day, disabled) {
    if (disabled) {
      return `<div class="py-2 text-center text-sm text-sand-300">${day}</div>`
    }
    return `<button type="button" data-date="${iso}"
      data-action="click->search-range#pick mouseenter->search-range#hover"
      class="mx-auto flex h-9 w-9 items-center justify-center rounded-full text-sm">${day}</button>`
  }

  paintDays() {
    const hi = this.checkOut || (this.checkIn && !this.checkOut ? this.hoverDate : null)
    const picking = this.checkIn && !this.checkOut
    const minOut = picking ? this.minCheckout() : null
    const buttons = this.calendarTarget.querySelectorAll("button[data-date]")
    buttons.forEach((button) => {
      const iso = button.dataset.date
      let state = "base"
      if (picking && iso > this.checkIn && iso < minOut) {
        state = "blocked" // completing here would be under the minimum stay
      } else if (this.checkIn && hi && hi > this.checkIn) {
        if (iso === this.checkIn || iso === hi) state = "endpoint"
        else if (iso > this.checkIn && iso < hi) state = "between"
      } else if (iso === this.checkIn) {
        state = "endpoint"
      }
      button.classList.remove(
        "bg-brand-700", "text-white", "bg-brand-100", "text-brand-800",
        "text-sand-800", "hover:bg-brand-50", "text-sand-300", "cursor-not-allowed"
      )
      if (state === "endpoint") button.classList.add("bg-brand-700", "text-white")
      else if (state === "between") button.classList.add("bg-brand-100", "text-brand-800")
      else if (state === "blocked") button.classList.add("text-sand-300", "cursor-not-allowed")
      else button.classList.add("text-sand-800", "hover:bg-brand-50")
    })
  }

  // First selectable check-out for the current check-in, honoring the minimum stay.
  minCheckout() {
    const d = this.parse(this.checkIn)
    d.setDate(d.getDate() + Math.max(this.minNightsValue, 1))
    return this.iso(d)
  }

  // --- date helpers (local time, no DST surprises for whole days) -------------

  parse(iso) {
    const [y, m, d] = iso.split("-").map(Number)
    return new Date(y, m - 1, d)
  }

  iso(date) {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`
  }

  monthLabel() {
    return new Date(this.viewYear, this.viewMonth, 1)
      .toLocaleDateString(this.localeValue || "es", { month: "long", year: "numeric" })
  }

  format(iso) {
    return this.parse(iso).toLocaleDateString(this.localeValue || "es", { day: "numeric", month: "short" })
  }
}
