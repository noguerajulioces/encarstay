# Self-hosted Plausible Analytics

The public site loads the Plausible tracking script only when `PLAUSIBLE_DOMAIN`
is set (see `app/views/layouts/application.html.erb`). The admin panel is never
tracked. Until the env var is set, nothing renders — the integration is inert.

## Environment variables (app side)

| Variable | Required | Example | Notes |
|---|---|---|---|
| `PLAUSIBLE_DOMAIN` | yes | `encarstays.com` | The site name as registered in Plausible. Enables the script. |
| `PLAUSIBLE_SRC` | no | `https://analytics.encarstays.com/js/script.outbound-links.js` | Defaults to `https://plausible.<PLAUSIBLE_DOMAIN>/js/script.outbound-links.js`. |

The `outbound-links` script variant tracks clicks to external sites — useful to
count how many visitors leave for Airbnb or WhatsApp. Add those as goals in the
Plausible dashboard ("Outbound Link: Click").

## Hosting Plausible Community Edition

Plausible CE runs as its own small stack (Plausible + PostgreSQL + ClickHouse),
separate from the Rails app. Official guide: https://github.com/plausible/community-edition

On the server (or any VPS with ~2 GB RAM):

```bash
git clone https://github.com/plausible/community-edition plausible
cd plausible
```

Create `.env`:

```env
BASE_URL=https://plausible.encarstays.com
SECRET_KEY_BASE=$(openssl rand -base64 48)
HTTP_PORT=8000
```

Then:

```bash
docker compose up -d
```

Point the `plausible.encarstays.com` DNS record at the server and terminate SSL
in front of port 8000 (Cloudflare, Caddy, or the Kamal proxy if it runs on the
same host). Open `BASE_URL`, create the admin account, and register the site
with the same name you set in `PLAUSIBLE_DOMAIN`.

## Wiring it into the app deploy

In `config/deploy.yml`:

```yaml
env:
  clear:
    PLAUSIBLE_DOMAIN: encarstays.com
    # PLAUSIBLE_SRC: https://analytics.encarstays.com/js/script.outbound-links.js
```

Redeploy and verify the `<script defer data-domain=...>` tag appears in the
page source of the public site (and that visits show up in the dashboard).

## Notes

- Plausible CE is cookieless — no consent banner needed.
- To reduce adblocker losses later, the script can be proxied through the app
  domain (see "proxying" in the Plausible docs); start simple without it.
- Keep ClickHouse data on a volume and include it in server backups if visit
  history matters.
