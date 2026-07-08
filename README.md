# Encar Stays — Reservas

Sistema de **reservas directas** para alquileres temporales: catálogo público
multilingüe (ES/EN/PT) donde los huéspedes buscan por fechas, ven un presupuesto y
reservan sin intermediarios, más un panel de administración y sincronización de
calendarios con Airbnb vía iCal.

> Documentación completa (dominio, presupuestos, flujos):
> **[docs/DOCUMENTACION.md](docs/DOCUMENTACION.md)**
> · Esquema de **base de datos** con diagramas: **[docs/DATABASE.md](docs/DATABASE.md)**

## Stack

Ruby 4.0.3 · Rails 8.1 · SQLite · Hotwire (Turbo + Stimulus) · Tailwind ·
Propshaft · Solid Queue/Cache/Cable · Kamal para despliegue.

## Puesta en marcha

Requisitos: **Ruby 4.0.3** (ver `.ruby-version`) y SQLite.

```bash
bin/setup      # instala gems, prepara la base y arranca la app
```

O paso a paso:

```bash
bundle install
bin/rails db:prepare   # crea, migra y siembra la base (idempotente)
bin/dev                # arranca servidor + watcher de Tailwind (Procfile.dev)
```

La app queda en http://localhost:3000. El panel de administración está en
`/admin`.

**Administrador de desarrollo** (creado por `db/seeds.rb`):

```
email:    admin@reservas.test
password: password
```

## Configuración

- **Base de datos:** SQLite en `storage/`. Producción usa bases separadas para la
  app, cache, cola de jobs y cable (`config/database.yml`).
- **Idiomas:** `es` por defecto (sin prefijo), `en` (`/en`), `pt` (`/pt`).
  Traducciones de UI en `config/locales/`.
- **Moneda:** PYG por defecto, USD soportado. Los importes se guardan en centavos.
- **Emails:** ver `app/mailers/booking_mailer.rb` (remitente por defecto en
  `ApplicationMailer`).

## Servicios en segundo plano

Jobs con **Solid Queue** (Active Job). Tareas programadas en
`config/recurring.yml`, principalmente la importación de calendarios de Airbnb cada
30 minutos. En desarrollo se ejecutan con el proceso web; en producción con el
supervisor de Solid Queue.

## Tests y calidad

```bash
bin/rails test              # suite de tests (test/)
bundle exec rubocop         # estilo (rubocop-rails-omakase)
bundle exec brakeman        # análisis de seguridad
bundle exec bundler-audit   # auditoría de dependencias
```

## Despliegue

Con **Kamal** (Docker). Configuración en `config/deploy.yml` y `.kamal/`:

```bash
bin/kamal deploy
```

## Estructura

```
app/
  models/            Property, Booking, Quote (presupuesto), SeasonalRate, Block,
                     CalendarSource, ExternalEvent, GuideEntry, Category, User…
  models/concerns/   OccupiesDates, Monetizable, Translatable
  controllers/       público (properties, bookings, searches…) y admin/
  jobs/              importación de calendarios iCal
  mailers/           notificaciones de reserva
db/schema.rb         esquema de la base de datos
config/routes.rb     rutas públicas (multilingües) y de admin
docs/                documentación del proyecto
```

## Documentación

- **[docs/DOCUMENTACION.md](docs/DOCUMENTACION.md)** — arquitectura, conceptos de
  dominio, sistema de **presupuestos**, flujo de reserva, sincronización con
  Airbnb, panel de administración e i18n.
- **[docs/DATABASE.md](docs/DATABASE.md)** — esquema de **base de datos** con
  diagramas gráficos (entidad-relación y flujos) y detalle de cada tabla.
# encarstay
