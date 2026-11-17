#!/bin/sh
# Railway entrypoint for Mixpost Lite. Runs as root; upstream's own start script does the Laravel work.
set -e

: "${PORT:=8080}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD is not set}"
: "${APP_KEY:?APP_KEY is not set}"
: "${DB_HOST:?DB_HOST is not set}"
: "${DB_PASSWORD:?DB_PASSWORD is not set}"
: "${REDIS_HOST:?REDIS_HOST is not set}"

# Public URL: the deploy's own domain unless the deployer set APP_URL (a custom domain).
if [ -z "$APP_URL" ] && [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
  APP_URL="https://$RAILWAY_PUBLIC_DOMAIN"
fi
export APP_URL
export REDIS_PASSWORD="${REDIS_PASSWORD:-null}"

# Upstream waits 30 s for the database and then carries on regardless, which leaves a web server with no tables when MariaDB is
# still initialising its first volume. Wait here, up to ten minutes, so the migration always runs against a live database.
: "${DB_PORT:=3306}"
n=0
until MYSQL_PWD="$DB_PASSWORD" mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -D "$DB_DATABASE" -N -B -e 'select 1' >/dev/null 2>&1; do
  n=$((n + 1))
  [ "$n" -le 200 ] || { echo "[railway] database $DB_HOST:$DB_PORT never became ready" >&2; exit 1; }
  sleep 3
done
echo "[railway] database ready after $((n * 3))s"

# nginx on Railway's injected PORT, IPv4 and IPv6 (the private network is IPv6).
sed -i "s#listen 80;#listen ${PORT}; listen [::]:${PORT};#" /etc/nginx/sites-available/default
grep -q "listen ${PORT};" /etc/nginx/sites-available/default

# A volume at storage/app hides what the image put there; recreate the directories the app writes to.
mkdir -p /var/www/html/storage/app/public /var/www/html/storage/app/mixpost-temp
echo "[railway] port=${PORT} appUrl=${APP_URL:-unset} storageOwner=$(stat -c %u:%g /var/www/html/storage/app)"

exec /usr/local/bin/upstream-start.sh
