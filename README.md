# Encar Stays — Bookings

[![CI](https://github.com/noguerajulioces/encarstay/actions/workflows/ci.yml/badge.svg)](https://github.com/noguerajulioces/encarstay/actions/workflows/ci.yml)
![Ruby](https://img.shields.io/badge/Ruby-4.0.3-CC342D?logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-8.1-CC0000?logo=rubyonrails&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite&logoColor=white)
![Hotwire](https://img.shields.io/badge/Hotwire-Turbo%20%2B%20Stimulus-5CD8E5?logoColor=black)
![Tailwind CSS](https://img.shields.io/badge/Tailwind-4-38BDF8?logo=tailwindcss&logoColor=white)

A **direct-booking** system for short-term rentals: a multilingual public catalogue
(ES/EN/PT) where guests search by date — as a list or on an interactive map — see a
quote, and book without intermediaries, plus a local guide, an SEO blog, an admin
panel, and two-way calendar sync with Airbnb over iCal.

> Full documentation (domain, quotes, flows):
> **[docs/DOCUMENTATION.md](docs/DOCUMENTATION.md)**
> · **Database** schema with diagrams: **[docs/DATABASE.md](docs/DATABASE.md)**

## Stack

Ruby 4.0.3 · Rails 8.1 · SQLite · Hotwire (Turbo + Stimulus) · Tailwind ·
Propshaft · Solid Queue/Cache/Cable · Kamal for deployment.

## Getting started

Requirements: **Ruby 4.0.3** (see `.ruby-version`) and SQLite.

```bash
bin/setup      # installs gems, prepares the database, and boots the app
```

Or step by step:

```bash
bundle install
bin/rails db:prepare   # creates, migrates, and seeds the database (idempotent)
bin/dev                # boots the server + Tailwind watcher (Procfile.dev)
```

The app runs at http://localhost:3000. The admin panel lives at `/admin`.

**Development admin** (created by `db/seeds.rb`):

```
email:    admin@reservas.test
password: password
```

## Configuration

- **Database:** SQLite in `storage/`. Production uses separate databases for the
  app, cache, job queue, and cable (`config/database.yml`).
- **Languages:** `es` by default (no prefix), `en` (`/en`), `pt` (`/pt`).
  UI translations live in `config/locales/`.
- **Currency:** PYG by default, USD supported. Amounts are stored in cents.
- **Emails:** see `app/mailers/booking_mailer.rb` (default sender in
  `ApplicationMailer`).

## Background services

Jobs run on **Solid Queue** (Active Job). Scheduled tasks live in
`config/recurring.yml`, mainly the Airbnb calendar import every 30 minutes. In
development they run inside the web process; in production under the Solid Queue
supervisor.

## Tests and quality

```bash
bin/rails test              # test suite (test/)
bundle exec rubocop         # style (rubocop-rails-omakase)
bundle exec brakeman        # security analysis
bundle exec bundler-audit   # dependency audit
```

## Deployment

With **Kamal** (Docker). Configuration in `config/deploy.yml` and `.kamal/`:

```bash
bin/kamal deploy
```

## Structure

```
app/
  models/            Property, Booking, Quote, SeasonalRate, Block, CalendarSource,
                     ExternalEvent, GuideEntry, Category, Post, Search, User…
  models/concerns/   OccupiesDates, Monetizable, Translatable
  controllers/       public (properties, searches+map, posts, bookings…) and admin/
  javascript/        Stimulus controllers (search_map, map_picker, gallery…)
  jobs/              iCal calendar import
  mailers/           booking notifications
db/schema.rb         database schema
config/routes.rb     public (multilingual) and admin routes
docs/                project documentation
```

## Documentation

- **[docs/DOCUMENTATION.md](docs/DOCUMENTATION.md)** — architecture, domain
  concepts, the **quote** pricing system, booking flow, Airbnb sync, admin panel,
  and i18n.
- **[docs/DATABASE.md](docs/DATABASE.md)** — **database** schema with graphical
  diagrams (entity-relationship and flows) and a column-by-column breakdown of
  every table.
