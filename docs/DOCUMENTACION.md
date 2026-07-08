# Documentación — Encar Stays (Reservas)

Sistema de **reservas directas** para alquileres temporales. Un catálogo público
multilingüe donde los huéspedes buscan por fechas, piden un presupuesto y reservan
sin intermediarios, más un panel de administración para gestionar propiedades,
precios, calendarios y reservas. Sincroniza disponibilidad con Airbnb vía iCal en
ambos sentidos.

- **Stack:** Ruby 4.0.3 · Rails 8.1 · SQLite · Hotwire (Turbo + Stimulus) · Tailwind · Propshaft · Solid Queue/Cache/Cable
- **Idiomas:** Español (por defecto, sin prefijo), Inglés (`/en`), Portugués (`/pt`)
- **Moneda:** Guaraníes (PYG) por defecto; USD soportado

## Índice

1. [Arquitectura](#arquitectura)
2. [Conceptos de dominio](#conceptos-de-dominio)
3. [Presupuestos (Quotes / precios)](#presupuestos-quotes--precios)
4. [Base de datos](#base-de-datos) → **[docs/DATABASE.md](DATABASE.md)** (diagramas)
5. [Flujo de reserva](#flujo-de-reserva)
6. [Sincronización de calendarios (Airbnb)](#sincronización-de-calendarios-airbnb)
7. [Panel de administración](#panel-de-administración)
8. [Internacionalización](#internacionalización)
9. [Jobs y tareas programadas](#jobs-y-tareas-programadas)
10. [Puesta en marcha](#puesta-en-marcha)

---

## Arquitectura

Aplicación Rails monolítica "omakase". Sin API externa: el sitio público y el
panel de administración se sirven desde la misma app con vistas server-rendered y
Turbo para la interactividad.

```
Huésped ──► Sitio público (ES/EN/PT)
              │  buscar · ver propiedad · presupuestar · reservar
              ▼
          Booking (reserva) ──► emails (huésped + admin)
              │
Admin ──► Panel /admin ──► confirmar / cancelar · propiedades · precios · bloqueos
              │
              ▼
        Calendarios iCal ◄──► Airbnb
          · saliente: feed tokenizado con fechas ocupadas
          · entrante: importa eventos externos cada ~30 min
```

**Patrones destacados:**

- **Objetos de dominio planos.** `Quote` y `Search` no son tablas: son POROs /
  objetos ActiveModel que encapsulan lógica de precios y filtrado.
- **Concerns reutilizables** (`app/models/concerns/`):
  - `OccupiesDates` — da a bookings, blocks y external_events un scope
    `overlapping(check_in, check_out)` común. Rangos **semiabiertos** `[from, to)`:
    el día de salida queda libre.
  - `Monetizable` — expone columnas `*_cents` (unidades menores) como accesores en
    la unidad mayor para los formularios del admin.
  - `Translatable` — expone `title` (etc.) leyendo la columna del locale actual
    (`title_es`, `title_en`, `title_pt`) con fallback al idioma por defecto.

---

## Conceptos de dominio

| Concepto | Modelo | Qué es |
|---|---|---|
| Propiedad | `Property` | Alojamiento publicable con precio base, capacidad y calendario propio. |
| Presupuesto | `Quote` | Cálculo de precio de una estadía (no se persiste hasta reservar). |
| Reserva | `Booking` | Solicitud de un huésped; ocupa fechas mientras está `pending`/`confirmed`. |
| Tarifa de temporada | `SeasonalRate` | Precio por noche y mínimo de noches para un rango de fechas. |
| Bloqueo | `Block` | Fechas cerradas manualmente por el administrador. |
| Fuente de calendario | `CalendarSource` | URL iCal de Airbnb a importar. |
| Evento externo | `ExternalEvent` | Reserva importada desde una fuente iCal. |
| Guía / contenido | `GuideEntry` + `Category` | Atracciones y eventos locales para promocionar. |
| Usuario | `User` | Administrador con acceso al panel. |

**La regla de oro de disponibilidad** (`Property#available?`): una propiedad está
libre para una estadía cuando **nada en el mercado** la solapa — ni una reserva
activa, ni un bloqueo manual, ni un evento externo importado.

---

## Presupuestos (Quotes / precios)

El **presupuesto** es el corazón del sistema de precios. `Quote`
([app/models/quote.rb](../app/models/quote.rb)) cotiza una estadía sin tocar la
base de datos; se usa en tres lugares:

1. El **cotizador público** de la ficha de propiedad.
2. Los **resultados de búsqueda**.
3. Se **congela** dentro de un `Booking` al momento de crearlo (los importes
   quedan grabados en la reserva y no cambian aunque cambien las tarifas después).

### Cómo se calcula

```
subtotal   = Σ  rate_for(noche)     para cada noche en [check_in, check_out)
cleaning   = property.cleaning_fee_cents
total      = subtotal + cleaning
depósito   = ceil(total / 2)        ← la "seña" para reservar
```

- **`rate_for(fecha)`** ([property.rb](../app/models/property.rb)): la tarifa de la
  temporada que cubre esa fecha, o el `base_price_cents` de la propiedad si ninguna
  temporada aplica. Cada noche se cobra a su tarifa vigente, así que una estadía que
  cruza dos temporadas mezcla precios noche a noche.
- **Depósito / seña** (`deposit_cents`): la mitad del total, redondeada hacia
  arriba. Es lo que el huésped paga por adelantado para retener la reserva.
- **Mínimo de noches** (`min_nights_on(fecha)`): el mayor entre el mínimo de la
  propiedad y el de la temporada que cubre esa fecha. Una temporada puede subirlo,
  nunca bajarlo.

### Precios almacenados en centavos

Todos los importes se guardan en **unidades menores** (`*_cents`, × 100). El
concern `Monetizable` los convierte a la unidad mayor solo para mostrar/editar en
formularios. En PYG, `45_000_000` cents = ₲450.000.

> **Importante:** un `Booking` guarda `subtotal_cents`, `cleaning_fee_cents` y
> `total_cents` propios, calculados por el callback `before_validation :price` al
> crearse. Editar tarifas de la propiedad **no** re-cotiza reservas existentes.

---

## Base de datos

El esquema completo, con **diagramas gráficos** (entidad-relación y flujos de
ocupación / presupuesto) y el detalle de cada tabla columna por columna, vive en su
propio documento:

> 📊 **[docs/DATABASE.md](DATABASE.md)**

En resumen: SQLite en las cuatro instancias de producción (principal + cache +
queue + cable, ver [config/database.yml](../config/database.yml)); esquema fuente en
[db/schema.rb](../db/schema.rb). El agregado central es `properties`, del que cuelgan
fotos, tarifas de temporada, bloqueos, reservas y fuentes de calendario. La guía
local (`guide_entries` + `categories`) se cruza con propiedades vía
`property_recommendations` (N:M).

---

## Flujo de reserva

```
1. Huésped busca (fechas + huéspedes)  ──► Search#results filtra propiedades disponibles
2. Abre una propiedad                  ──► ve el Quote (subtotal, limpieza, total, seña)
3. Envía el formulario de reserva      ──► BookingsController#create
     · honeypot anti-spam (campo `company` oculto)
     · Property#book! con with_lock → re-chequea disponibilidad e inserta
     · Booking congela precios y genera code RES-XXXX (status: pending)
4. Emails automáticos:
     · guest_requested  → al huésped, en su idioma
     · admin_requested  → a los admins, con link para bloquear en Airbnb
5. Admin confirma       ──► Booking#confirm! + email `confirmed` al huésped
   (o cancela)          ──► Booking#cancel! libera las fechas
```

El huésped consulta su reserva en `/reservas/RES-XXXX` (`bookings#show`) por código.

---

## Sincronización de calendarios (Airbnb)

Bidireccional, para que Airbnb y el sitio directo no doble-reserven.

**Saliente** (`CalendarFeed`, `calendars#show`): un feed `.ics` por propiedad en
`/calendars/:calendar_token/:slug`. Publica **solo fechas ocupadas** (bookings
activos + bloqueos) — nunca datos del huésped. El `calendar_token` secreto es la
única llave. Se pega en Airbnb como "Importar calendario".

**Entrante** (`CalendarSource#import!`): descarga cada `.ics`, hace **upsert por
UID**, borra los eventos que desaparecieron del feed (= cancelados arriba), y por
cada evento nuevo/cambiado que **solape una reserva directa** dispara un
`collision_alert` por email al admin.

> **La ventana de ~2 h.** La importación corre cada 30 minutos, así que existe un
> hueco donde una reserva directa recién hecha aún no aparece en Airbnb. Mitigación:
> el email `admin_requested` incluye un enlace directo para bloquear esas fechas en
> el anuncio de Airbnb manualmente y cerrar la ventana.

---

## Panel de administración

Bajo `/admin`, layout propio, protegido por `Admin::BaseController#require_admin`
(sesión + `Current.user`). Login en `/admin/session`.

- **Dashboard** — reservas pendientes, llegadas/salidas de los próximos 7 días,
  alertas de sincronización fallida y % de ocupación del mes.
- **Reservas** — listar, ver, crear manualmente, **confirmar**, **cancelar**.
- **Propiedades** — CRUD + tarifas de temporada, fotos, fuentes de calendario y
  sincronización manual (`/sync`).
- **Bloqueos** — crear/eliminar fechas cerradas.
- **Guía** — entradas (atracciones/eventos), categorías, recomendaciones.
- **Calendario** — vista consolidada de ocupación.

---

## Internacionalización

Tres locales fijos: `es` (por defecto, sin prefijo), `en` (`/en`), `pt` (`/pt`).
El routing usa `scope "(:locale)"` con constraint `locale: /en|pt/`.

- **Contenido de UI:** archivos `config/locales/{es,en,pt}.yml`.
- **Contenido de datos:** columnas por locale (`title_es`, …) vía concern
  `Translatable`, con fallback al idioma por defecto.
- **Reservas:** cada `Booking` recuerda su `locale` para que los emails salgan en
  el idioma en que el huésped reservó.

---

## Jobs y tareas programadas

Solid Queue como backend de Active Job. Programación en
[config/recurring.yml](../config/recurring.yml) (solo en producción):

| Job / comando | Frecuencia | Qué hace |
|---|---|---|
| `ImportAllCalendarsJob` | cada 30 min | Encola un `ImportCalendarJob` por fuente activa. |
| `ImportCalendarJob` | (encolado) | Importa una fuente; reintenta 3× con backoff. |
| `SolidQueue::Job.clear_finished_in_batches` | cada hora | Limpia jobs terminados. |

---

## Puesta en marcha

Requisitos: Ruby 4.0.3, SQLite. Ver el [README](../README.md) para el detalle.

```bash
bin/setup                 # instala gems, prepara la base y arranca
# o manualmente:
bundle install
bin/rails db:prepare      # crea + migra + seed
bin/dev                   # servidor + watcher de Tailwind (Procfile.dev)
```

- **Admin de desarrollo (seed):** `admin@reservas.test` / `password`
- **Tests:** `bin/rails test` (unitarios) · `bin/rails test:system` si aplica
- **Despliegue:** Kamal (Docker) — ver `config/deploy.yml` y `.kamal/`
- **Seguridad:** `bundle exec brakeman` · `bundle exec bundler-audit`
- **Estilo:** `bundle exec rubocop` (rubocop-rails-omakase)
