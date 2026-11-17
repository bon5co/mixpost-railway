# mixpost-railway

Wrapper image for [Mixpost Lite](https://github.com/inovector/mixpost) (v2.6.0) on [Railway](https://railway.com).

Upstream's start script creates a default administrator (`admin@example.com` / `changeme`) on a fresh database, which is a
known login on every new deployment. The wrapper replaces that step with `railway:admin`, which creates or re-syncs the
administrator from `ADMIN_EMAIL` and `ADMIN_PASSWORD` on every boot. It also waits for the database before migrating, makes
nginx listen on Railway's injected `PORT` (IPv4 and IPv6), trusts Railway's proxy headers and builds `APP_URL` from
`RAILWAY_PUBLIC_DOMAIN`.

- Needs: MariaDB or MySQL (`DB_HOST`, `DB_PASSWORD`, defaults `DB_DATABASE=mixpost`, `DB_USERNAME=mixpost`) and Redis (`REDIS_HOST`, `REDIS_PASSWORD`)
- Variables: `APP_KEY` (exactly 32 characters), `ADMIN_PASSWORD` (at least 12 characters), `ADMIN_EMAIL`
- Volume: `/var/www/html/storage/app` (uploaded media)
- Health: `GET /mixpost/login`

Published as `ghcr.io/bon5co/mixpost-railway`. Template: see the Railway marketplace listing.
