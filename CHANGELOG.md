# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-07-08

### Added

- **SEO blog.** Trilingual `Post` model (es/en/pt) with per-locale Trix
  rich-text bodies, slug, published/featured flags and cover image. Admin CRUD
  at `/admin/posts` and a public `/blog` index plus article pages. Full search
  engine support: `BlogPosting` + `BreadcrumbList` JSON-LD, `Blog` schema on the
  index, `og:type=article` metadata, sitemap entries and `hreflang` alternates.
  Action Text is installed with the Trix editor CSS scoped to the admin form so
  it never loads on public pages.
- **Map-based search.** `/search` becomes an Airbnb-style split view — a results
  list beside an interactive Leaflet map (OpenStreetMap, no API key) that works
  with or without a date range. Includes toggleable layers (stays / attractions
  / events) and POI category filters.
- **Date-range availability search.** Localized check-in / check-out date range
  picker driving the availability search.
- **Airbnb-style photo gallery.** Property pages gain a photo gallery with a
  full-screen viewer, localized in all three languages.
- **File uploads on the property form.** The admin property form now supports
  multipart submissions for image uploads.

### Changed

- Serve a 1200×630 `og:image` variant instead of the full-size original.
- Demote Trix-authored `<h1>` to `<h2>` so each article keeps a single
  top-level `<h1>`; added `article:published_time`, `article:modified_time`,
  `article:section` and `og:locale:alternate` metadata site-wide.
- Documentation refreshed: `DOCUMENTATION.md` (search/map and blog sections, the
  `Post` domain concept, the Action Text pattern), `DATABASE.md` (the `posts`
  and `action_text_rich_texts` tables, ER diagram) and `README.md`.

### Tests

- Added `Post` model, search-map integration and blog SEO coverage; extended the
  admin flow and SEO integration tests.

## [0.1.0]

Baseline release: property listings, availability booking, admin panel,
trilingual guide content and internationalization (es/en/pt). Established before
this changelog was introduced.

[Unreleased]: https://github.com/noguerajulioces/encarstay/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/noguerajulioces/encarstay/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/noguerajulioces/encarstay/releases/tag/v0.1.0
