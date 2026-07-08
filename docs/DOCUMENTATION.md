# Documentation — Encar Stays (Bookings)

A **direct-booking** system for short-term rentals. A multilingual public catalogue
where guests search by date — as a list or on an interactive map — request a quote,
and book without intermediaries, plus an admin panel to manage properties, pricing,
calendars, bookings, the local guide, and a blog. It syncs availability with Airbnb
over iCal in both directions.

- **Stack:** Ruby 4.0.3 · Rails 8.1 · SQLite · Hotwire (Turbo + Stimulus) · Tailwind · Propshaft · Solid Queue/Cache/Cable
- **Languages:** Spanish (default, no prefix), English (`/en`), Portuguese (`/pt`)
- **Currency:** Guaraníes (PYG) by default; USD supported

## Contents

1. [Architecture](#architecture)
2. [Domain concepts](#domain-concepts)
3. [Quotes (pricing)](#quotes-pricing)
4. [Search and map](#search-and-map)
5. [Content: guide and blog](#content-guide-and-blog)
6. [Database](#database) → **[docs/DATABASE.md](DATABASE.md)** (diagrams)
7. [Booking flow](#booking-flow)
8. [Calendar sync (Airbnb)](#calendar-sync-airbnb)
9. [Admin panel](#admin-panel)
10. [Internationalization](#internationalization)
11. [Jobs and scheduled tasks](#jobs-and-scheduled-tasks)
12. [Getting started](#getting-started)

---

## Architecture

A monolithic "omakase" Rails application. No external API: the public site and the
admin panel are served from the same app with server-rendered views and Turbo for
interactivity.

```
Guest ──► Public site (ES/EN/PT)
              │  search (list + map) · view property · quote · book
              │  browse guide (attractions / events) · read blog
              ▼
          Booking ──► emails (guest + admin)
              │
Admin ──► /admin panel ──► confirm / cancel · properties · pricing · blocks
              │                guide · blog · categories
              ▼
        iCal calendars ◄──► Airbnb
          · outbound: tokenized feed with occupied dates
          · inbound: imports external events every ~30 min
```

**Notable patterns:**

- **Plain domain objects.** `Quote` and `Search` are not tables: they are POROs /
  ActiveModel objects that encapsulate pricing and filtering logic.
- **Reusable concerns** (`app/models/concerns/`):
  - `OccupiesDates` — gives bookings, blocks, and external_events a shared
    `overlapping(check_in, check_out)` scope. **Half-open** ranges `[from, to)`:
    the check-out day stays free.
  - `Monetizable` — exposes `*_cents` columns (minor units) as accessors in the
    major unit for admin forms.
  - `Translatable` — exposes `title` (etc.) by reading the current locale's column
    (`title_es`, `title_en`, `title_pt`) with a fallback to the default language.
- **Action Text (Trix).** Blog posts store a rich-text body per locale
  (`body_es`/`body_en`/`body_pt` via `has_rich_text`); `Post#body` returns the
  current locale's version, falling back to Spanish. The Trix editor CSS is scoped to
  the admin form so it never loads on public pages.

---

## Domain concepts

| Concept | Model | What it is |
|---|---|---|
| Property | `Property` | A publishable rental with a base price, capacity, and its own calendar. |
| Quote | `Quote` | The price calculation for a stay (not persisted until booking). |
| Booking | `Booking` | A guest's request; occupies dates while `pending`/`confirmed`. |
| Seasonal rate | `SeasonalRate` | Per-night price and minimum nights for a date range. |
| Block | `Block` | Dates closed manually by the admin. |
| Calendar source | `CalendarSource` | An Airbnb iCal URL to import. |
| External event | `ExternalEvent` | A booking imported from an iCal source. |
| Guide / content | `GuideEntry` + `Category` | Local attractions and events to promote; plotted on the search map. |
| Blog post | `Post` | A multilingual article (Trix rich text) publishing local SEO content. |
| User | `User` | An admin with panel access. |

**The golden rule of availability** (`Property#available?`): a property is free for a
stay when **nothing on the market** overlaps it — no active booking, no manual block,
and no imported external event.

---

## Quotes (pricing)

The **quote** is the heart of the pricing system. `Quote`
([app/models/quote.rb](../app/models/quote.rb)) prices a stay without touching the
database; it is used in three places:

1. The **public quote widget** on the property page.
2. The **search results**.
3. It is **frozen** inside a `Booking` at creation time (the amounts are recorded on
   the booking and do not change even if rates change later).

### How it is calculated

```
subtotal   = Σ  rate_for(night)     for each night in [check_in, check_out)
cleaning   = property.cleaning_fee_cents
total      = subtotal + cleaning
deposit    = ceil(total / 2)        ← the down payment to book
```

- **`rate_for(date)`** ([property.rb](../app/models/property.rb)): the rate of the
  season covering that date, or the property's `base_price_cents` if no season
  applies. Each night is charged at its effective rate, so a stay that crosses two
  seasons mixes prices night by night.
- **Deposit / down payment** (`deposit_cents`): half the total, rounded up. It is
  what the guest pays up front to hold the booking.
- **Minimum nights** (`min_nights_on(date)`): the greater of the property's minimum
  and the covering season's minimum. A season can raise it, never lower it.

### Prices stored in cents

All amounts are stored in **minor units** (`*_cents`, × 100). The `Monetizable`
concern converts them to the major unit only for display/editing in forms. In PYG,
`45_000_000` cents = ₲450,000.

> **Important:** a `Booking` stores its own `subtotal_cents`, `cleaning_fee_cents`,
> and `total_cents`, computed by the `before_validation :price` callback at creation.
> Editing a property's rates does **not** re-quote existing bookings.

---

## Search and map

Search is a plain object, not a table. `Search`
([app/models/search.rb](../app/models/search.rb)) carries `check_in`, `check_out`,
and `guests`:

- `#results` — active properties that fit the guests **and** are available for the range.
- `#list` — the left-hand results list: `#results` when a valid date range is given,
  otherwise the whole active catalogue, so the map is useful before any dates are picked.

`SearchesController#show` renders an Airbnb-style split view: the results list on the
left and an interactive **Leaflet** map on the right. The map is fed three
date-independent datasets — geolocated **properties**, **attractions**, and **events** —
serialized to JSON in `data-*` attributes and drawn by the `search_map` Stimulus
controller
([app/javascript/controllers/search_map_controller.js](../app/javascript/controllers/search_map_controller.js)).

- **Tiles:** OpenStreetMap (no API key, no cost) — the same setup as the admin
  map-picker used to place a property's pin.
- **Layers:** three toggleable marker groups (stays / attractions / events), each with
  a distinct pin color. Points of interest are further filterable by `Category`.
- **Coordinates** are admin-entered (`latitude` / `longitude`); proximity uses the
  haversine `Property#distance_km_to`. The map only plots records that have coordinates.

---

## Content: guide and blog

Two editorial content types, both multilingual and managed from the admin panel:

- **Guide** — `GuideEntry` (`kind`: `attraction` or `event`) grouped by `Category`.
  Promotes the area, appears on the search map, and cross-links to stays through
  `property_recommendations` (N:M).
- **Blog** — `Post`, for local SEO content about Encarnación. Mirrors the guide's
  conventions (slug from `title_es`, `published` / `featured`, cover image, optional
  `Category`) but stores its body as **Action Text** rich text, one record per locale.

**Blog SEO.** Each article page emits a unique title, meta description, canonical URL,
and a single `<h1>` (Trix's in-body headings are demoted to `<h2>`), plus full Open
Graph (`og:type=article`, `article:published_time` / `article:modified_time`, a
1200×630 image), a Twitter card, and `BlogPosting` + `BreadcrumbList` JSON-LD. The
`/blog` index emits `Blog` JSON-LD. Every post is added to `sitemap.xml` with per-locale
`hreflang` alternates. The shared head partial is
[app/views/shared/_meta.html.erb](../app/views/shared/_meta.html.erb).

---

## Database

The full schema, with **graphical diagrams** (entity-relationship and occupancy /
quote flows) and a column-by-column breakdown of every table, lives in its own
document:

> 📊 **[docs/DATABASE.md](DATABASE.md)**

In short: SQLite across the four production instances (primary + cache + queue +
cable, see [config/database.yml](../config/database.yml)); source schema in
[db/schema.rb](../db/schema.rb). The central aggregate is `properties`, which owns
photos, seasonal rates, blocks, bookings, and calendar sources. The local guide
(`guide_entries` + `categories`) is cross-linked to properties via
`property_recommendations` (N:M). Blog articles live in `posts`, with their per-locale
rich-text bodies stored by Action Text in `action_text_rich_texts`.

---

## Booking flow

```
1. Guest searches (dates + guests)     ──► Search#results filters available properties
2. Opens a property                    ──► sees the Quote (subtotal, cleaning, total, deposit)
3. Submits the booking form            ──► BookingsController#create
     · anti-spam honeypot (hidden `company` field)
     · Property#book! with with_lock → re-checks availability and inserts
     · Booking freezes prices and generates code RES-XXXX (status: pending)
4. Automatic emails:
     · guest_requested  → to the guest, in their language
     · admin_requested  → to the admins, with a link to block the dates on Airbnb
5. Admin confirms       ──► Booking#confirm! + `confirmed` email to the guest
   (or cancels)         ──► Booking#cancel! frees the dates
```

The guest looks up their booking at `/reservas/RES-XXXX` (`bookings#show`) by code.

---

## Calendar sync (Airbnb)

Two-way, so Airbnb and the direct site do not double-book.

**Outbound** (`CalendarFeed`, `calendars#show`): one `.ics` feed per property at
`/calendars/:calendar_token/:slug`. It publishes **occupied dates only** (active
bookings + blocks) — never guest data. The secret `calendar_token` is the only key.
It is pasted into Airbnb as "Import calendar".

**Inbound** (`CalendarSource#import!`): downloads each `.ics`, **upserts by UID**,
deletes events that disappeared from the feed (= cancelled upstream), and for each
new/changed event that **overlaps a direct booking** fires a `collision_alert` email
to the admin.

> **The ~2 h window.** The import runs every 30 minutes, so there is a gap where a
> just-made direct booking does not yet show up on Airbnb. Mitigation: the
> `admin_requested` email includes a direct link to block those dates on the Airbnb
> listing manually and close the window.

---

## Admin panel

Under `/admin`, with its own layout, protected by
`Admin::BaseController#require_admin` (session + `Current.user`). Login at
`/admin/session`.

- **Dashboard** — pending bookings, arrivals/departures for the next 7 days, failed
  sync alerts, and the month's occupancy %.
- **Bookings** — list, view, create manually, **confirm**, **cancel**.
- **Properties** — CRUD + seasonal rates, photos, calendar sources, and manual
  sync (`/sync`).
- **Blocks** — create/delete closed dates.
- **Guide** — entries (attractions/events), categories, recommendations.
- **Blog** — articles with a Trix rich-text editor (one per locale) and a cover image.
- **Calendar** — a consolidated occupancy view.

---

## Internationalization

Three fixed locales: `es` (default, no prefix), `en` (`/en`), `pt` (`/pt`). Routing
uses `scope "(:locale)"` with the constraint `locale: /en|pt/`.

- **UI content:** `config/locales/{es,en,pt}.yml` files.
- **Data content:** per-locale columns (`title_es`, …) via the `Translatable`
  concern, with a fallback to the default language.
- **Rich text:** blog bodies use Action Text with one rich-text record per locale
  (`body_es` / `body_en` / `body_pt`); `Post#body` picks the current locale, falling
  back to Spanish.
- **Bookings:** each `Booking` remembers its `locale` so emails go out in the
  language the guest booked in.

---

## Jobs and scheduled tasks

Solid Queue as the Active Job backend. Scheduling in
[config/recurring.yml](../config/recurring.yml) (production only):

| Job / command | Frequency | What it does |
|---|---|---|
| `ImportAllCalendarsJob` | every 30 min | Enqueues an `ImportCalendarJob` per active source. |
| `ImportCalendarJob` | (enqueued) | Imports one source; retries 3× with backoff. |
| `SolidQueue::Job.clear_finished_in_batches` | hourly | Cleans up finished jobs. |

---

## Getting started

Requirements: Ruby 4.0.3, SQLite. See the [README](../README.md) for details.

```bash
bin/setup                 # installs gems, prepares the database, and boots
# or manually:
bundle install
bin/rails db:prepare      # create + migrate + seed
bin/dev                   # server + Tailwind watcher (Procfile.dev)
```

- **Development admin (seed):** `admin@reservas.test` / `password`
- **Tests:** `bin/rails test` (unit) · `bin/rails test:system` if applicable
- **Deployment:** Kamal (Docker) — see `config/deploy.yml` and `.kamal/`
- **Security:** `bundle exec brakeman` · `bundle exec bundler-audit`
- **Style:** `bundle exec rubocop` (rubocop-rails-omakase)
