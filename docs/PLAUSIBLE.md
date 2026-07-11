# Self-hosted Plausible Analytics

Visits are tracked with a self-hosted [Plausible Community Edition](https://github.com/plausible/community-edition)
instance running on the same VPS as the app.

## How it's wired

Plausible CE does **not** support serving its dashboard under a URL path, so the
setup splits in two:

- **Tracking** is first-party: the app proxies the tracker script and the event
  endpoint under its own domain (`/plausible/js/script.outbound-links.js` and
  `/plausible/api/event` → `PlausibleProxyController` → the Plausible server).
  Nothing loads from a third-party origin, and adblockers don't filter it.
- **The dashboard** (owner-only) is served by the Plausible stack directly on
  port 8000 of the VPS: `http://2.25.149.103:8000`.

The tracking script only renders when `PLAUSIBLE_DOMAIN` is set (see
`app/views/layouts/application.html.erb`); the proxy only forwards when
`PLAUSIBLE_BACKEND_URL` is set. Without them the whole integration is inert.
The admin panel is never tracked.

| Variable | Example | Notes |
|---|---|---|
| `PLAUSIBLE_DOMAIN` | `2.25.149.103` | Must equal the site name registered in Plausible. Swap for the real domain later. |
| `PLAUSIBLE_BACKEND_URL` | `http://host.docker.internal:8000` | Where the proxy forwards to. `host.docker.internal` reaches the VPS host from the app container (wired via `add-host` in `config/deploy.yml`). |

Both are set in `config/deploy.yml` under `env.clear`.

## 1. Prepare the VPS (once)

```bash
ssh root@2.25.149.103

# Docker (also needed by Kamal)
curl -fsSL https://get.docker.com | sh

# Firewall: SSH, app, Plausible dashboard
ufw allow 22 && ufw allow 80 && ufw allow 8000 && ufw enable
```

## 2. Stand up Plausible CE

```bash
git clone https://github.com/plausible/community-edition /opt/plausible
cd /opt/plausible

cat > .env <<EOF
BASE_URL=http://2.25.149.103:8000
SECRET_KEY_BASE=$(openssl rand -base64 48)
HTTP_PORT=8000
EOF

docker compose up -d
```

Open `http://2.25.149.103:8000`, create the owner account, and **add a site
with the domain `2.25.149.103`** — it must match `PLAUSIBLE_DOMAIN` exactly.

Then lock registration down:

```bash
echo "DISABLE_REGISTRATION=true" >> .env
docker compose up -d
```

## 3. Deploy the app with Kamal

`config/deploy.yml` is set for the VPS (2.25.149.103), images on GitHub
Container Registry, no SSL until there is a domain.

From your machine:

```bash
# GitHub personal access token (classic) with write:packages
export KAMAL_REGISTRY_PASSWORD=ghp_...

# First deploy (installs kamal-proxy on the server, builds, pushes, boots)
bin/kamal setup

# Subsequent deploys
bin/kamal deploy
```

The site comes up at `http://2.25.149.103`. Verify:

- Page source contains `<script defer data-domain="2.25.149.103" data-api="/plausible/api/event" src="/plausible/js/script.outbound-links.js">`.
- `curl -I http://2.25.149.103/plausible/js/script.outbound-links.js` → 200.
- Visit the site, then check the dashboard at `:8000` — the visit should appear
  in real time.

In the dashboard, add goals for **Outbound Link: Click** to count clicks out to
Airbnb and WhatsApp.

## When the domain arrives

1. Point DNS at 2.25.149.103.
2. `config/deploy.yml`: set `proxy: ssl: true, host: <domain>`; change
   `APP_HOST` and `PLAUSIBLE_DOMAIN` to the domain.
3. Enable `config.assume_ssl` / `config.force_ssl` in `config/environments/production.rb`.
4. Plausible: change `BASE_URL` in `/opt/plausible/.env` and restart; rename the
   site's domain in the dashboard (Site settings → change domain) to match.
5. Optionally close port 8000 (`ufw deny 8000`) and access the dashboard via an
   SSH tunnel, or give Plausible its own subdomain later.

## Notes

- Plausible CE is cookieless — no consent banner needed.
- ClickHouse data lives in Docker volumes under `/opt/plausible`; include them
  in server backups if visit history matters.
- The proxy fails soft: if the Plausible stack is down, the site keeps working
  and the proxy answers 502 (script) with no visitor-facing impact.
